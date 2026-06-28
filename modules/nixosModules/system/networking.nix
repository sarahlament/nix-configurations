{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.networking = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) mkIf mkForce;
    inherit (self.myLib.directory) hosts peers;
    inherit (self.myLib.constants) fqdn;
    inherit (self.myLib.constants.addresses) internal;
    inherit (self.myLib.helpers) mkSopsFile;
    inherit (config.networking) hostName;
    wgPort = 51820;

    host = self.myLib.directory.hosts.${hostName};
    isHub = host.roles.wgHub or false;

    # look for the first host that defines they are a 'hub' in the directory
    # fine for one coordinator, TODO recheck when adding a second
    hub =
      lib.findFirst (host: host.roles.wgHub or false)
      (throw "network: no wgHub defined in directory")
      (lib.attrValues hosts);

    # similarly, look for the first resolver in the directory
    # same as above, TODO recheck when adding a second
    resolver =
      lib.findFirst (host: host.roles.resolver or false)
      (throw "network: no resolver defined in directory")
      (lib.attrValues hosts);

    # this is for the hub, each peer restricted to its defined internal IP
    spokePeers =
      lib.mapAttrsToList (_: host: {
        publicKey = host.keys.wgPub;
        allowedIPs = ["${host.ip.internal}/128"];
      })
      (lib.filterAttrs (n: _: n != hostName) hosts // peers);

    # this is for the spokes, we trust the coordinator to verify the connection and route properly
    hubPeer = {
      publicKey = hub.keys.wgPub;
      endpoint = "[${hub.ip.public.v6}]:${toString wgPort}";
      allowedIPs = [internal];
      persistentKeepalive = 25;
    };
  in {
    sops.secrets."${hostName}WgKey" = {
      sopsFile = mkSopsFile "privkeys";
      restartUnits = ["wireguard-internal.service"];
    };
    services.resolved.enable = mkForce false;
    networking = {
      useDHCP = true;
      dhcpcd.extraConfig = "nohook resolv.conf";
      search = [fqdn];
      nftables.enable = true;

      nameservers = [resolver.ip.internal "1.1.1.1"];
      firewall = {
        trustedInterfaces = ["internal"];
        allowedUDPPorts = mkIf isHub [wgPort];
      };

      wireguard.interfaces.internal = {
        ips = ["${host.ip.internal}/48"];
        listenPort = mkIf isHub wgPort;
        privateKeyFile = config.sops.secrets."${hostName}WgKey".path;
        peers =
          if isHub
          then spokePeers
          else [hubPeer];

        # hub-routed spoke<->spoke (phone -> ishtar) needs forwarding on the hub.
        # not needed yet (2 nodes, services live on the hub). when it is:
        postSetup = mkIf isHub "echo 1 > /proc/sys/net/ipv6/conf/internal/forwarding";
      };
    };
  };
}
