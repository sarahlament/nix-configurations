{ self, ... }: {
  flake.nixosModules.networking =
    {
      config,
      lib,
      ...
    }:
    let
      inherit (lib) mkIf mkForce;
      inherit (self.myLib.directory) hosts peers;
      inherit (self.myLib.constants) fqdn wgPort;
      inherit (self.myLib.constants.addresses) internal;
      inherit (self.myLib.helpers) mkSopsFile roleHost;
      inherit (config.networking) hostName;

      host = self.myLib.directory.hosts.${hostName};
      isHub = host.roles.edge.vpn or false;

      # the coordinator and the recursive resolver; fine for one of each,
      # TODO recheck when adding a second
      hub = roleHost [
        "edge"
        "vpn"
      ];
      resolver = roleHost [
        "dns"
        "resolver"
      ];

      # this is for the hub, each peer restricted to its defined internal IP
      spokePeers = lib.mapAttrsToList (_: host: {
        publicKey = host.keys.wgPub;
        allowedIPs = [ "${host.ip.internal}/128" ];
      }) (lib.filterAttrs (n: _: n != hostName) hosts // peers);

      # this is for the spokes, we trust the coordinator to verify the connection and route properly
      hubPeer = {
        publicKey = hub.keys.wgPub;
        endpoint = "${hub.ip.public.v4}:${toString wgPort}";
        allowedIPs = [ internal ];
        persistentKeepalive = 25;
      };

      # site-local mesh: hosts sharing a `site` reach each other directly over the
      # LAN instead of hairpinning through the hub. the /128 endpoint beats the
      # hubPeer's /48, so same-site traffic routes direct; a stale LAN lease just
      # falls back to the hub route (i.e. today's behavior).
      mySite = host.site or null;
      siteMates = lib.filterAttrs (
        n: h: n != hostName && mySite != null && (h.site or null) == mySite
      ) hosts;
      hasSiteMates = siteMates != { };
      sitePeers = lib.mapAttrsToList (_: h: {
        publicKey = h.keys.wgPub;
        allowedIPs = [ "${h.ip.internal}/128" ];
        endpoint = "${h.ip.site}:${toString wgPort}";
        persistentKeepalive = 25;
      }) siteMates;
    in
    {
      sops.secrets."${hostName}WgKey" = {
        sopsFile = mkSopsFile "privkeys/${hostName}";
        restartUnits = [ "wireguard-internal.service" ];
      };
      services.resolved.enable = mkForce false;

      boot.kernel.sysctl = {
        # phone -> ishtar (spoke<->spoke) routes through the hub, so the hub must forward.
        # IPv6 gates its forwarding datapath on the GLOBAL knob; per-interface forwarding
        # is only the NDP host/router role, so this has to be conf.all, not conf.internal.
        "net.ipv6.conf.all.forwarding" = mkIf isHub 1;

        # services bind their WG internal address, which may not be up when they
        # start; allow the bind regardless of interface state.
        "net.ipv6.ip_nonlocal_bind" = 1;
      };

      networking = {
        useDHCP = true;
        dhcpcd.extraConfig = "nohook resolv.conf";
        search = [ fqdn ];
        nftables.enable = true;

        nameservers = [
          resolver.ip.internal
          "1.1.1.1"
        ];
        firewall = {
          trustedInterfaces = [ "internal" ];
          # site members must accept inbound handshakes from their LAN neighbors
          allowedUDPPorts = mkIf (isHub || hasSiteMates) [ wgPort ];
        };

        wireguard.interfaces.internal = {
          ips = [ "${host.ip.internal}/48" ];
          listenPort = mkIf (isHub || hasSiteMates) wgPort;
          privateKeyFile = config.sops.secrets."${hostName}WgKey".path;
          peers = if isHub then spokePeers else [ hubPeer ] ++ sitePeers;
        };
      };
    };
}
