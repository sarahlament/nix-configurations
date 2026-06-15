{
  config,
  lib,
  pkgs,
  self,
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

  systemd.services.caddy.serviceConfig.EnvironmentFile = config.sops.templates.porkbunAcme.path;
  services.caddy = {
    globalConfig = ''
      acme_dns porkbun {
        api_key {env.PORKBUN_API_KEY}
        api_secret_key {env.PORKBUN_SECRET_API_KEY}
      }
    '';
    package = pkgs.caddy.withPlugins {
      plugins = ["github.com/caddy-dns/porkbun@v0.3.1"];
      hash = "sha256-MlKX2obWac+jP4j9UHFMxsY/DRaqw9JCVAdI7erhFwo=";
    };
  };
  security.acme = {
    acceptTerms = true;
    defaults.email = "sarah@${fqdn}";
    certs."mail.${fqdn}" = {
      dnsProvider = "porkbun";
      group = "dovecot2";
      extraLegoRenewFlags = ["--reuse-key"];
      postRun = "systemctl reload postfix dovecot";
      environmentFile = config.sops.templates.porkbunAcme.path;
    };
  };

  services.borgbackup.jobs.${config.networking.hostName}.paths = [
    config.security.acme.certs."mail.${fqdn}".directory
  ];
}
