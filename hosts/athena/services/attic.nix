{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  # Import the attic server module
  imports = [
    inputs.atticserver.nixosModules.atticd
  ];

  # Enable PostgreSQL for Attic's database
  services.postgresql = {
    enable = true;
    ensureDatabases = ["atticd"];
    ensureUsers = [
      {
        name = "atticd";
        ensureDBOwnership = true;
      }
    ];
  };

  # Configure Attic server
  services.atticd = {
    enable = true;

    # Credentials and secrets
    environmentFile = config.sops.secrets.attic-credentials.path;

    settings = {
      # Listen on localhost, Caddy will handle the reverse proxy
      listen = "127.0.0.1:8080";

      # API endpoint (publicly accessible URL)
      api-endpoint = "https://attic.lament.gay/";

      # Database configuration
      database.url = "postgresql:///atticd?host=/run/postgresql";

      # Storage configuration
      storage = {
        type = "local";
        path = "/var/lib/atticd/storage";
      };

      # Compression settings
      compression = {
        type = "zstd";
      };

      # Garbage collection
      garbage-collection = {
        interval = "12 hours";
        default-retention-period = "6 months";
      };
    };
  };

  # SOPS secret for Attic credentials
  sops.secrets.attic-credentials = {
    owner = "atticd";
    group = "atticd";
  };

  # Ensure storage directory exists with correct permissions
  systemd.tmpfiles.rules = [
    "d /var/lib/atticd/storage 0750 atticd atticd -"
  ];
}
