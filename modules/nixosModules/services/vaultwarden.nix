{ self, ... }: {
  flake.nixosModules.vaultwarden =
    { config, ... }:
    let
      inherit (self.myLib.constants) fqdn;
      inherit (self.myLib.helpers) mkPrivateProxy mkSopsFile;
      inherit (self.myLib.directory.hosts.${config.networking.hostName}) ip;
    in
    {
      sops.secrets.vaultwardenToken = {
        sopsFile = mkSopsFile "services";
      };
      services = {
        borgbackup.jobs.${config.networking.hostName} = {
          preHook = "systemctl start backup-vaultwarden.service";
          paths = [ config.services.vaultwarden.backupDir ];
        };
        caddy = {
          virtualHosts."vault.${fqdn}" = {
            extraConfig = ''
              encode zstd gzip
              ${mkPrivateProxy ip.internal config.services.vaultwarden.config.ROCKET_PORT}
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
