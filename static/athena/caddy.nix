{
  config,
  lib,
  pkgs,
  self,
  ...
}: {
  # we use linode's DNS for athena, so we use its DNS-01 acme provider
  sops.secrets.linode-token = {};
  systemd.services.caddy.serviceConfig.EnvironmentFile = config.sops.secrets.linode-token.path;
  services.caddy = {
    globalConfig = "acme_dns linode {env.LINODE_TOKEN}";
    package = pkgs.caddy.withPlugins {
      plugins = ["github.com/caddy-dns/linode@v0.8.0"];
      hash = "sha256-PVD5zn7gcljGbRrw8ZHMdZxowymNDcXgYuvD1wGijAU=";
    };
  };
}
