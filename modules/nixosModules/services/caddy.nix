{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.caddy = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (self.myLib.constants) fqdn;
  in {
    networking.firewall.allowedTCPPorts = [
      80 # HTTP
      443 # HTTPS
    ];
    services.caddy = {
      enable = true;
      package = pkgs.caddy.withPlugins {
        plugins = ["github.com/caddy-dns/linode@v0.8.0"];
        hash = "sha256-PVD5zn7gcljGbRrw8ZHMdZxowymNDcXgYuvD1wGijAU=";
      };

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
}
