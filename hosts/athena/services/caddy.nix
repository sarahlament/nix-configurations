{
  config,
  lib,
  pkgs,
  ...
}: {
  networking.firewall.allowedTCPPorts = [
    80 # HTTP
    443 # HTTPS
  ];
  services.caddy = {
    enable = true;

    # Main site
    virtualHosts."lament.gay" = {
      extraConfig = ''
        root * /var/www/lament.gay
        file_server
      '';
    };

    # Vaultwarden
    virtualHosts."vaultwarden.lament.gay" = {
      extraConfig = ''
        encode zstd gzip

        reverse_proxy localhost:${toString config.services.vaultwarden.config.ROCKET_PORT} {
          header_up X-Real-IP {remote_host}
        }
      '';
    };

    # Headscale
    virtualHosts."headscale.lament.gay" = {
      extraConfig = ''
        reverse_proxy localhost:${toString config.services.headscale.port} {
          header_up Host {upstream_hostport}
          header_up X-Real-IP {remote_host}
        }
      '';
    };

    # Webmail (uncomment when you add one like Roundcube)
    # virtualHosts."mail.lament.gay" = {
    #   extraConfig = ''
    #     reverse_proxy localhost:8081
    #   '';
    # };
  };

  # Create web root directory
  systemd.tmpfiles.rules = [
    "d /var/www/lament.gay 0755 caddy caddy -"
  ];
}
