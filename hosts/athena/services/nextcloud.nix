{
  config,
  pkgs,
  lib,
  ...
}: let
  fpm = config.services.phpfpm.pools.nextcloud;
in {
  # stolen from https://github.com/onny/nixos-nextcloud-testumgebung/blob/main/nextcloud-extras.nix
  # Disable nginx (enabled by default with Nextcloud)
  services.nginx.enable = lib.mkForce false;

  services.phpfpm.pools.nextcloud.settings = {
    "listen.owner" = config.services.caddy.user;
    "listen.group" = config.services.caddy.group;
  };

  users.users.caddy.extraGroups = ["nextcloud"];

  # while we do reference nginx while it is disabled, the configs are still populated when its forced off, so we just piggy back off that
  services.caddy.virtualHosts."cloud.lament.gay" = {
    extraConfig = ''
      encode zstd gzip

      root * ${config.services.nginx.virtualHosts."cloud.lament.gay".root}

      redir /.well-known/carddav /remote.php/dav 301
      redir /.well-known/caldav /remote.php/dav 301
      redir /.well-known/* /index.php{uri} 301
      redir /remote/* /remote.php{uri} 301

      header {
        Strict-Transport-Security max-age=31536000
        Permissions-Policy interest-cohort=()
        X-Content-Type-Options nosniff
        X-Frame-Options SAMEORIGIN
        Referrer-Policy no-referrer
        X-XSS-Protection "1; mode=block"
        X-Permitted-Cross-Domain-Policies none
        X-Robots-Tag "noindex, nofollow"
        -X-Powered-By
      }

      php_fastcgi unix/${fpm.socket} {
        root ${config.services.nginx.virtualHosts."cloud.lament.gay".root}
        env front_controller_active true
        env modHeadersAvailable true
      }

      @forbidden {
        path /build/* /tests/* /config/* /lib/* /3rdparty/* /templates/* /data/*
        path /.* /autotest* /occ* /issue* /indie* /db_* /console*
        not path /.well-known/*
      }
      error @forbidden 404

      @immutable {
        path *.css *.js *.mjs *.svg *.gif *.png *.jpg *.ico *.wasm *.tflite
        query v=*
      }
      header @immutable Cache-Control "max-age=15778463, immutable"

      @static {
        path *.css *.js *.mjs *.svg *.gif *.png *.jpg *.ico *.wasm *.tflite
        not query v=*
      }
      header @static Cache-Control "max-age=15778463"

      @woff2 path *.woff2
      header @woff2 Cache-Control "max-age=604800"

      file_server
    '';
  };

  sops.secrets.nextcloud-admin-pass = {
    owner = "nextcloud";
    group = "nextcloud";
  };

  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud32;
    hostName = "cloud.lament.gay";

    # Database - PostgreSQL recommended
    database.createLocally = true;

    config = {
      adminuser = "admin";
      adminpassFile = config.sops.secrets.nextcloud-admin-pass.path;
      dbtype = "pgsql";
    };

    # HTTPS via Caddy
    https = true;

    # Performance tuning
    phpOptions = {
      "memory_limit" = "512M";
      "upload_max_filesize" = lib.mkForce "4G";
      "post_max_size" = lib.mkForce "4G";
    };

    # Redis for caching (big performance boost)
    configureRedis = true;

    # Allow app installs
    extraAppsEnable = true;

    settings = {
      # Trust Caddy proxy
      trusted_proxies = ["127.0.0.1"];

      # Mail integration (uses your mailserver)
      mail_domain = "lament.gay";
      mail_from_address = "nextcloud";
      mail_smtpmode = "smtp";
      mail_smtphost = "127.0.0.1";
      mail_smtpport = 25;

      # Maintenance window (1 AM)
      maintenance_window_start = 1;
    };
  };
}
