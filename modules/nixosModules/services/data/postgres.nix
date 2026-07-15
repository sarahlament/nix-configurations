{ ... }: {
  # standalone shared postgres server. knows nothing about its tenants: each
  # consuming service declares its own database + role by appending to
  # ensureDatabases / ensureUsers (nixos merges the lists), and the backup job
  # dumps whatever databases exist.
  flake.nixosModules.postgres =
    {
      config,
      pkgs,
      ...
    }:
    let
      inherit (config.networking) hostName;
    in
    {
      services = {
        postgresql = {
          enable = true;
          # pinned so a nixpkgs default bump can't strand the version-locked
          # datadir. major upgrades stay a deliberate pg_dump/restore, never a
          # surprise on rebuild.
          package = pkgs.postgresql_17;
        };

        # native pg_dump per database on a daily timer -> /var/backup/postgresql.
        # databases list tracks whatever tenants have declared, so new consumers
        # are backed up automatically.
        postgresqlBackup = {
          enable = true;
          databases = config.services.postgresql.ensureDatabases;
        };

        # hand the DUMP dir to the shared host borg job (never the live cluster).
        # can't use vaultwarden's preHook-forces-fresh-dump trick here: preHook is
        # a single non-mergeable string vaultwarden already owns. we rely on the
        # daily timer instead; systemd Before= ordering is the follow-up if fresh
        # dumps at backup time ever matter.
        borgbackup.jobs.${hostName}.paths = [
          config.services.postgresqlBackup.location
        ];
      };

      # persist entries must own their dirs; a plain string lands root:root and
      # the bind mount locks postgres out of its own state on a fresh boot.
      # persist the dump dir too so there's no empty-backup window before the
      # first timer fires post-reboot.
      environment.persistence."/persist".directories = [
        {
          directory = "/var/lib/postgresql";
          user = "postgres";
          group = "postgres";
          mode = "0700";
        }
        {
          directory = config.services.postgresqlBackup.location;
          user = "postgres";
          group = "postgres";
          mode = "0700";
        }
      ];
    };
}
