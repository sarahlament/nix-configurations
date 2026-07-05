{ self, ... }: {
  flake.nixosModules.acme =
    { config, ... }:
    let
      inherit (self.myLib.constants) fqdn;
    in
    {
      imports = [ self.nixosModules.tsig ];

      security.acme = {
        acceptTerms = true;
        defaults = {
          email = "sarah@${fqdn}";
          dnsProvider = "rfc2136";
          environmentFile = config.sops.templates.acmeTsig.path;
        };
      };
    };
}
