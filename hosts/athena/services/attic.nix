{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  # Caddy reverse proxy configuration
  services.caddy.virtualHosts."attic.lament.gay" = {
    extraConfig = ''
      encode zstd gzip
      reverse_proxy localhost:8085
    '';
  };

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
      listen = "127.0.0.1:8085";

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

      # Chunking settings
      chunking = {
        nar-size-threshold = 64 * 1024; # 64 KiB
        min-size = 16 * 1024; # 16 KiB
        avg-size = 64 * 1024; # 64 KiB
        max-size = 256 * 1024; # 256 KiB
      };

      # Garbage collection
      garbage-collection = {
        interval = "12 hours";
        default-retention-period = "6 months";
      };
    };
  };

  # SOPS secret for Attic credentials
  sops.secrets.attic-credentials = {};

  # Ensure storage directory exists with correct permissions
  systemd.tmpfiles.rules = [
    "d /var/lib/atticd/storage 0750 atticd atticd -"
  ];
}
