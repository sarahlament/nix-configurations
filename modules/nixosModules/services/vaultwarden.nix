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
    inherit (self.myLib.helpers) mkReverseProxy;
  in {
    sops.secrets.vaultwardenToken = {};
    services = {
      borgbackup.jobs.${config.networking.hostName} = {
        preHook = "systemctl start backup-vaultwarden.service";
        paths = [config.services.vaultwarden.backupDir];
      };
      caddy = {
        virtualHosts."vault.${fqdn}" = {
          extraConfig = ''
            encode zstd gzip
            ${mkReverseProxy config.services.vaultwarden.config.ROCKET_PORT}
          '';
        };
      };
      vaultwarden = {
        enable = true;
        backupDir = "/var/backup/vaultwarden";
        environmentFile = config.sops.secrets.vaultwardenToken.path;

        config = {
          DOMAIN = "https://vault.${fqdn}";
          SIGNUPS_ALLOWED = false;

          ROCKET_ADDRESS = "127.0.0.1";
          ROCKET_PORT = 8222;
          ROCKET_LOG = "critical";
        };
      };
    };
  };
}
