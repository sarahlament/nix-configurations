{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.kresd = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (self.myLib.constants) fqdn;
    inherit (self.myLib.directory.hosts.${config.networking.hostName}) ip;
    inherit (self.myLib.directory) hosts services;
    hostHints = lib.concatStringsSep "\n" (
      lib.mapAttrsToList (_: host: "hints['${host.hostname}.${fqdn}'] = '${host.ip.internal}'")
      (lib.filterAttrs (_: host: (host ? ip) && (host.ip ? internal))
        self.myLib.directory.hosts)
    );

    serviceHints = lib.concatStringsSep "\n" (
      lib.flatten (
        lib.mapAttrsToList (
          hostName: svcs:
            map (svc: "hints['${svc}.${fqdn}'] = '${hosts.${hostName}.ip.internal}'") svcs
        ) (services.private or {})
      )
    );
  in {
    networking.nameservers = lib.mkForce ["::1"];
    services.kresd = {
      enable = true;
      listenPlain = ["127.0.0.1:53" "[::1]:53" "[${ip.internal}]:53"];
      extraConfig = ''
        modules.load('hints')
        hints.use_nodata(true)

        ${hostHints}
        ${serviceHints}
      '';
    };
  };
}
