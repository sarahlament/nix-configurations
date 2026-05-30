{
  config,
  lib,
  pkgs,
  self,
  ...
}: {
  # we use linode's DNS for athena, so we use its DNS-01 acme provider
  sops.secrets.linode-token = {};
  services.caddy.globalConfig = "acme_dns linode {env.LINODE_TOKEN}";
  systemd.services.caddy.serviceConfig.EnvironmentFile = config.sops.secrets.linode-token.path;
}
