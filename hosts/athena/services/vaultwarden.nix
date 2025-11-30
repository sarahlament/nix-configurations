{
  config,
  lib,
  pkgs,
  ...
}: {
  services.vaultwarden = {
    enable = true;
    backupDir = "/var/backup/vaultwarden";

    config = {
      DOMAIN = "https://vaultwarden.lament.gay";
      SIGNUPS_ALLOWED = true; # Set to false after creating your account

      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = 8222;
      ROCKET_LOG = "critical";
    };

    environmentFile = config.sops.secrets.vaultwarden-env.path;
  };

  sops.secrets.vaultwarden-env = {};

  # Backup timer
  systemd.tmpfiles.rules = [
    "d /var/backup/vaultwarden 0700 root root -"
  ];

  systemd.services.vaultwarden-backup = {
    description = "Backup Vaultwarden data";
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
    path = [config.services.vaultwarden.package pkgs.sqlite];
    script = ''
      BACKUP_DIR="/var/backup/vaultwarden"
      DATE=$(date +%Y%m%d-%H%M%S)

      # SQLite online backup
      sqlite3 /var/lib/vaultwarden/db.sqlite3 ".backup '$BACKUP_DIR/db-$DATE.sqlite3'"

      # Attachments
      if [ -d /var/lib/vaultwarden/attachments ]; then
        cp -r /var/lib/vaultwarden/attachments "$BACKUP_DIR/attachments-$DATE"
      fi

      # Keep 7 days
      find "$BACKUP_DIR" -mtime +7 -delete
    '';
  };

  systemd.timers.vaultwarden-backup = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };
}
