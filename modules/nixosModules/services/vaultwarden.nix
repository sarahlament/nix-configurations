{ self, ... }: {
  flake.nixosModules.vaultwarden =
    { config, ... }:
    let
      inherit (self.myLib.constants) fqdn;
      inherit (self.myLib.helpers) mkSopsFile;
      inherit (self.myLib.directory.hosts.${config.networking.hostName}.ip) internal;
    in
    {
      sops.secrets.vaultwardenToken = {
        sopsFile = mkSopsFile "services";
      };

      # persist entry must own the dir; a plain string lands root:root and the bind
      # mount locks vaultwarden out of its own state on a fresh boot
      environment.persistence."/persist".directories = [
        {
          directory = "/var/lib/vaultwarden";
          user = "vaultwarden";
          group = "vaultwarden";
          mode = "0700";
        }
      ];

      services = {
        borgbackup.jobs.${config.networking.hostName} = {
          preHook = "systemctl start backup-vaultwarden.service";
          paths = [ config.services.vaultwarden.backupDir ];
        };
        vaultwarden = {
          enable = true;
          backupDir = "/var/backup/vaultwarden";
          environmentFile = config.sops.secrets.vaultwardenToken.path;

          config = {
            DOMAIN = "https://vault.${fqdn}";
            SIGNUPS_ALLOWED = false;

            ROCKET_ADDRESS = internal;
            ROCKET_PORT = self.myLib.directory.services.vault.port;
            ROCKET_LOG = "critical";
          };
        };
      };
    };
}
