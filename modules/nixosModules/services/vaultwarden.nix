{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.vaultwarden = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (self.myLib.constants) fqdn;
  in {
    services.caddy = {
      virtualHosts."vaultwarden.${fqdn}" = {
        extraConfig = ''
          encode zstd gzip

          reverse_proxy localhost:${toString config.services.vaultwarden.config.ROCKET_PORT} {
            header_up X-Real-IP {remote_host}
          }
        '';
      };
    };

    sops.secrets.vaultwardenToken = {};
    services.vaultwarden = {
      enable = true;
      backupDir = "/var/backup/vaultwarden";
      environmentFile = config.sops.secrets.vaultwardenToken.path;

      config = {
        DOMAIN = "https://vaultwarden.${fqdn}";
        SIGNUPS_ALLOWED = false;

        ROCKET_ADDRESS = "127.0.0.1";
        ROCKET_PORT = 8222;
        ROCKET_LOG = "critical";
      };
    };
  };
}
