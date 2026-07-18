{ self, ... }: {
  # LAN-facing DNS for the devices that aren't WG peers (TVs, IoT, guests).
  # deliberately NOT a directory.services entry: nothing here is proxied by the
  # edge, the dashboard is reachable on the LAN only.
  #
  # split of concerns, forced by the upstream module: pihole.toml is a mode-400
  # symlink into the nix store, so *settings* can only ever be declarative. what
  # stays mutable is gravity.db (adlists, allow/deny, regex, clients, groups) and
  # the query log - i.e. the whole day-to-day web UI loop. that's the intended
  # workflow for this box: plumbing declared once here, tinkering in the browser.
  flake.nixosModules.pihole =
    {
      config,
      lib,
      ...
    }:
    let
      inherit (lib) mkOption types mkForce;
      inherit (self.myLib.directory.services.pihole) port;
      cfg = config.modules.pihole;
      ftl = config.services.pihole-ftl;

      # unbound sits on loopback behind FTL. 5335 is the conventional pihole
      # +unbound port and keeps :53 free for FTL itself.
      recursorPort = 5335;
    in
    {
      options.modules.pihole = {
        interface = mkOption {
          type = types.str;
          description = "LAN interface FTL binds its DNS listener to";
        };
      };

      config = {
        services = {
          # FTL is dnsmasq under the hood - a forwarder, it cannot recurse.
          # unbound is the actual resolver; this host answers from the root zone
          # rather than leaning on athena's kresd, which is the point of the box.
          unbound = {
            enable = true;
            # unbound doesn't own this host's resolution path, FTL does.
            resolveLocalQueries = false;
            settings.server = {
              interface = [ "127.0.0.1" ];
              port = recursorPort;
              access-control = [ "127.0.0.0/8 allow" ];
              # residential recursion: keep the cache warm, since every cold
              # lookup is a full walk from the root and some authoritatives
              # rate-limit consumer IPs.
              prefetch = true;
              cache-min-ttl = 60;
              qname-minimisation = true;
              harden-glue = true;
              harden-dnssec-stripped = true;
              # 1232 avoids v6 fragmentation, which some authoritatives black-hole
              edns-buffer-size = 1232;
            };
          };

          pihole-ftl = {
            enable = true;
            # module default is `true`, which makes the API refuse writes. the UI
            # is this box's control surface, so let it through - settings still
            # can't persist (store symlink), but list/group management works.
            settings = {
              misc.readOnly = false;
              dns = {
                # BIND mode binds the LAN interface only. this is a laptop: it
                # will sit on hostile wifi at some point, and an open resolver on
                # a coffee shop network is a bad afternoon.
                inherit (cfg) interface;
                listeningMode = "BIND";
                upstreams = [ "127.0.0.1#${toString recursorPort}" ];
                domainNeeded = true;
                expandHosts = true;
              };
            };
            # deliberately empty. `lists` reloads into gravity.db on every start
            # and would stomp anything added through the UI - adlists are managed
            # in the browser on this host, not here.
            lists = [ ];
            # query log grows without bound otherwise; FTL's own reaper handles it.
            queryLogDeleter.enable = true;
          };

          # pihole-web owns settings.webserver.port, so the port is declared here
          # rather than in the FTL settings block.
          pihole-web = {
            enable = true;
            ports = [ port ];
          };

          # gravity.db is hand-curated through the UI, so it's the one thing here
          # that can't be rebuilt from the flake.
          borgbackup.jobs.${config.networking.hostName}.paths = [
            ftl.stateDirectory
          ];
        };

        # this host resolves through its own stack, not the fleet resolver that
        # system/net/networking.nix points every other host at.
        networking = {
          nameservers = mkForce [ "127.0.0.1" ];
          # listeningMode BIND already scopes the listener; scope the firewall to
          # match rather than using openFirewallDNS, which opens :53 globally.
          firewall.interfaces.${cfg.interface} = {
            allowedUDPPorts = [ 53 ];
            allowedTCPPorts = [
              53
              port
            ];
          };
        };

        # persist entries must own their dirs; a plain string lands root:root and
        # the bind mount locks the service out of its own state on a fresh boot.
        # gravity.db and the query log live here - without this, every reboot
        # throws away whatever was configured in the web UI.
        environment.persistence."/persist".directories = [
          {
            directory = ftl.stateDirectory;
            inherit (ftl) user group;
            mode = "0755";
          }
          # (logDirectory is under /var/log, which disko already gives its own
          # btrfs subvolume - it survives on its own and must not be persisted.)
          {
            # unbound's root trust anchor - refetching it every boot is rude to
            # the root servers and briefly breaks DNSSEC validation.
            directory = "/var/lib/unbound";
            user = "unbound";
            group = "unbound";
            mode = "0755";
          }
        ];
      };
    };
}
