{inputs, ...}: {
  flake.nixosModules.caddy = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) mkOption types;
    fqdn = config.modules.services.caddy.fqdn;
  in {
    options.modules.services.caddy.fqdn = mkOption {
      type = types.str;
      description = "FQDN for caddy";
      default = "localhost";
    };
    config = {
      networking.firewall.allowedTCPPorts = [
        80 # HTTP
        443 # HTTPS
      ];
      services.caddy = {
        enable = true;

        virtualHosts.${fqdn} = {
          extraConfig = ''
            root * /var/www/${fqdn}
            file_server
          '';
        };
      };

      systemd.tmpfiles.rules = [
        "d /var/www/${fqdn} 0755 caddy caddy -"
      ];
    };
  };
}
