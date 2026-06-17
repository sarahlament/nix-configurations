{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.acme = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (self.myLib.constants) fqdn;
    inherit (self.myLib.helpers) mkSopsFile;
  in {
    sops = {
      secrets = {
        porkbunApi = {sopsFile = mkSopsFile "services";};
        porkbunKey = {sopsFile = mkSopsFile "services";};
      };
      templates.porkbunAcme.content = ''
        PORKBUN_API_KEY=${config.sops.placeholder.porkbunApi}
        PORKBUN_SECRET_API_KEY=${config.sops.placeholder.porkbunKey}
      '';
    };

    security.acme = {
      acceptTerms = true;
      defaults = {
        email = "sarah@${fqdn}";
        dnsProvider = "porkbun";
        environmentFile = config.sops.templates.porkbunAcme.path;
      };
    };
  };
}
