{ self, ... }: {
  flake.nixosModules.kresd =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (self.myLib.constants) fqdn;
      inherit (self.myLib.directory.hosts.${config.networking.hostName}) ip;
      inherit (self.myLib.directory) services;

      # StevenBlack unified list, base + fakenews + gambling (no porn).
      blocklistUrl = "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling/hosts";
      blocklistPath = "/var/lib/knot-resolver/blocklist.rpz";

      # minimal valid RPZ so kresd loads cleanly before the timer's first run
      # (athena is impermanent - a fresh boot has no fetched list yet).
      seedRpz = pkgs.writeText "blocklist-seed.rpz" ''
        $TTL 2h
        @ SOA localhost. root.localhost. 1 12h 15m 3w 2h
        @ NS localhost.
      '';
      hostHints = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (_: host: "hints['${host.hostname}.${fqdn}'] = '${host.ip.internal}'") (
          lib.filterAttrs (_: host: (host ? ip) && (host.ip ? internal)) self.myLib.directory.hosts
        )
      );

      serviceHints = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (name: _: "hints['${name}.${fqdn}'] = '${ip.internal}'") (
          lib.filterAttrs (_: svc: !(svc.public or false)) services
        )
      );
    in
    {
      networking.nameservers = lib.mkForce [ "::1" ];
      services.kresd = {
        enable = true;
        listenPlain = [
          "127.0.0.1:53"
          "[::1]:53"
          "[${ip.internal}]:53"
        ];
        extraConfig = ''
          trust_anchors.set_insecure({'${fqdn}'})
          modules.load('hints')
          hints.use_nodata(true)

          -- ad/tracker blocklist; watch=false because this build lacks lua-cqueues,
          -- so the refresh timer restarts kresd to pick up a new list instead.
          policy.add(policy.rpz(policy.DENY, '${blocklistPath}', false))

          ${hostHints}
          ${serviceHints}
        '';
      };

      systemd = {
        # seed a valid RPZ if none exists yet, so kresd never fails to start.
        tmpfiles.rules = [
          "d /var/lib/knot-resolver 0750 knot-resolver knot-resolver -"
          "C ${blocklistPath} 0644 knot-resolver knot-resolver - ${seedRpz}"
        ];

        # refresh the blocklist daily; convert the hosts file to RPZ, then
        # restart kresd to load it (cache is on-disk, so nothing is lost).
        services.dns-blocklist = {
          description = "Refresh kresd ad/tracker blocklist";
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
          path = [
            pkgs.curl
            pkgs.gawk
            pkgs.coreutils
            pkgs.systemd
          ];
          serviceConfig.Type = "oneshot";
          script = ''
            tmp=$(mktemp)
            {
              printf '$TTL 2h\n@ SOA localhost. root.localhost. %s 12h 15m 3w 2h\n@ NS localhost.\n' "$(date +%s)"
              curl -fsSL '${blocklistUrl}' \
                | awk '/^0\.0\.0\.0/ && $2 != "0.0.0.0" { print $2" CNAME ." }'
            } > "$tmp"
            install -m0644 -o knot-resolver -g knot-resolver "$tmp" '${blocklistPath}'
            rm -f "$tmp"
            systemctl restart 'kresd@1.service'
          '';
        };

        timers.dns-blocklist = {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = "daily";
            Persistent = true;
            RandomizedDelaySec = "1h";
          };
        };
      };
    };
}
