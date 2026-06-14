{
  config,
  lib,
  pkgs,
  self,
  ...
}: let
  inherit (self.myLib.constants) fqdn;
  inherit (self.myLib.helpers) mkSecret;
in {
  sops.secrets.linodeToken = mkSecret {file = "services";};
  systemd.services.caddy.serviceConfig.EnvironmentFile = config.sops.secrets.linodeToken.path;
  services.caddy = {
    globalConfig = "acme_dns linode {env.LINODE_TOKEN}";
    package = pkgs.caddy.withPlugins {
      plugins = ["github.com/caddy-dns/linode@v0.8.0"];
      hash = "sha256-6vQy74JTlThRd6OFEdnF+IyTxWwhP14TARcFdgKuz/8=";
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

  services.borgbackup.jobs.${config.networking.hostName}.paths = [
    config.security.acme.certs."mail.${fqdn}".directory
  ];
}
