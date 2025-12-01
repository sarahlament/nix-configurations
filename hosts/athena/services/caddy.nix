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

    virtualHosts."mail.lament.gay" = {
      # empty for now, we just need it to handle the certificate
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/www/lament.gay 0755 caddy caddy -"
  ];
}
