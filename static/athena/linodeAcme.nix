{
  config,
  lib,
  pkgs,
  self,
  ...
}: let
  inherit (self.myLib.constants) fqdn;
in {
  sops.secrets.linodeToken = {};
  systemd.services.caddy.serviceConfig.EnvironmentFile = config.sops.secrets.linodeToken.path;
  services.caddy = {
    globalConfig = "acme_dns linode {env.LINODE_TOKEN}";
    package = pkgs.caddy.withPlugins {
      plugins = ["github.com/caddy-dns/linode@v0.8.0"];
      hash = "sha256-PVD5zn7gcljGbRrw8ZHMdZxowymNDcXgYuvD1wGijAU=";
    };
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "sarah@${fqdn}";
    certs."mail.${fqdn}" = {
      dnsProvider = "linode";
      group = "dovecot2";
      postRun = "systemctl reload postfix dovecot";
      environmentFile = config.sops.secrets.linodeToken.path;
    };
  };
}
