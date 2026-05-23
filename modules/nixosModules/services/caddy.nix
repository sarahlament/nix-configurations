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
        package = pkgs.caddy.withPlugins {
          plugins = ["github.com/caddy-dns/linode@v0.8.0"];
          hash = "sha256-LOcMK57SjR8wp8gVYaCYLnWqgYwEvzksn5rUdX71z4g=";
        };

        globalConfig = "acme_dns linode {env.LINODE_TOKEN}";
        virtualHosts.${fqdn} = {
          extraConfig = ''
            root * /var/www/${fqdn}
            file_server
          '';
        };
      };

      sops.secrets.linode-token = {};
      systemd.services.caddy.serviceConfig.EnvironmentFile = config.sops.secrets.linode-token.path;
      systemd.tmpfiles.rules = [
        "d /var/www/${fqdn} 0755 caddy caddy -"
      ];
    };
  };
}
