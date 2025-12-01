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

    virtualHosts."lament.gay" = {
      extraConfig = ''
        root * /var/www/lament.gay
        file_server
      '';
    };

    # HTTP-only server for ACME challenges
    extraConfig = ''
      http://mail.lament.gay {
        root * /var/lib/acme/acme-challenge
        file_server
      }
    '';
  };

  systemd.tmpfiles.rules = [
    "d /var/www/lament.gay 0755 caddy caddy -"
  ];
}
