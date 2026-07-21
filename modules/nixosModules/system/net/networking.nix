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
      inherit (self.myLib.constants) fqdn;
      inherit (self.myLib.constants.addresses) internal;
      inherit (self.myLib.helpers)
        mkSopsFile
        roleHost
        mkPeer
        portOf
        ;
      inherit (config.networking) hostName;

      host = self.myLib.directory.hosts.${hostName};
      isHub = host.roles.edge.vpn or false;

      # a host with a public endpoint listens for inbound WG and is directly
      # dialable. the hub always is; ishtar is meshed in as a second entry point
      # so the whole fleet hits it directly instead of hairpinning via the hub.
      hasPublic = host.ip ? public;
      isEntry = isHub || hasPublic;

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

      # every host that publishes a public endpoint is directly dialable. mkPeer
      # and portOf (which build/endpoint these) live in myLib.helpers.
      entryHosts = lib.filterAttrs (_: h: h.ip ? public) hosts;

      # the hub's default-route peer for a spoke: the whole mesh (/48) via the hub.
      hubPeer = {
        publicKey = hub.keys.wgPub;
        endpoint = "${hub.ip.public.v4}:${toString (portOf hub)}";
        allowedIPs = [ internal ];
        persistentKeepalive = 25;
      };

      # the hub accepts every other node; entry points among them get dialed too.
      spokePeers = lib.mapAttrsToList (_: mkPeer) (removeAttrs (hosts // peers) [ hostName ]);

      # a non-hub entry point (ishtar) accepts everyone but itself and the hub
      # (hubPeer is its /48 default route); entry points among them still dialed.
      inboundPeers = lib.mapAttrsToList (_: mkPeer) (
        removeAttrs (hosts // peers) [
          hostName
          hub.hostname
        ]
      );

      # non-hub entry points a plain spoke dials directly, so the whole fleet
      # reaches them without hairpinning through the hub (currently just ishtar).
      directEntries = lib.mapAttrsToList (_: mkPeer) (
        lib.filterAttrs (n: h: n != hostName && !(h.roles.edge.vpn or false)) entryHosts
      );
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
          allowedUDPPorts = mkIf isEntry [ (portOf host) ];
        };

        wireguard.interfaces.internal = {
          ips = [ "${host.ip.internal}/48" ];
          listenPort = mkIf isEntry (portOf host);
          privateKeyFile = config.sops.secrets."${hostName}WgKey".path;
          peers =
            if isHub then
              spokePeers
            else if hasPublic then
              [ hubPeer ] ++ inboundPeers
            else
              [ hubPeer ] ++ directEntries;
        };
      };
    };
}
