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
      isHub = host.roles.wgHub or false;

      # the coordinator and the recursive resolver; fine for one of each,
      # TODO recheck when adding a second
      hub = roleHost "wgHub";
      resolver = roleHost "resolver";

      # this is for the hub, each peer restricted to its defined internal IP
      spokePeers = lib.mapAttrsToList (_: host: {
        publicKey = host.keys.wgPub;
        allowedIPs = [ "${host.ip.internal}/128" ];
      }) (lib.filterAttrs (n: _: n != hostName) hosts // peers);

      # this is for the spokes, we trust the coordinator to verify the connection and route properly
      hubPeer = {
        publicKey = hub.keys.wgPub;
        endpoint = "${fqdn}:${toString wgPort}";
        allowedIPs = [ internal ];
        persistentKeepalive = 25;
      };
    in
    {
      sops.secrets."${hostName}WgKey" = {
        sopsFile = mkSopsFile "privkeys";
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
          allowedUDPPorts = mkIf isHub [ wgPort ];
        };

        wireguard.interfaces.internal = {
          ips = [ "${host.ip.internal}/48" ];
          listenPort = mkIf isHub wgPort;
          privateKeyFile = config.sops.secrets."${hostName}WgKey".path;
          peers = if isHub then spokePeers else [ hubPeer ];
        };
      };
    };
}
