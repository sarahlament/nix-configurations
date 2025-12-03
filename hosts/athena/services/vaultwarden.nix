{
  config,
  lib,
  pkgs,
  ...
}: {
  services.caddy = {
    virtualHosts."vaultwarden.lament.gay" = {
      extraConfig = ''
        encode zstd gzip

        reverse_proxy localhost:${toString config.services.vaultwarden.config.ROCKET_PORT} {
          header_up X-Real-IP {remote_host}
        }
      '';
    };
  };

  services.vaultwarden = {
    enable = true;
    backupDir = "/var/backup/vaultwarden";

    config = {
      DOMAIN = "https://vaultwarden.lament.gay";
      SIGNUPS_ALLOWED = false;

      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = 8222;
      ROCKET_LOG = "critical";
    };

    environmentFile = config.sops.secrets.vaultwarden-env.path;
  };

  sops.secrets.vaultwarden-env = {};
}
