{ self, ... }: {
  flake.nixosModules.kresd =
    {
      config,
      lib,
      ...
    }:
    let
      inherit (self.myLib.constants) fqdn;
      inherit (self.myLib.directory.hosts.${config.networking.hostName}) ip;
      inherit (self.myLib.directory) services;
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

          ${hostHints}
          ${serviceHints}
        '';
      };
    };
}
