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
      virtualHosts.${fqdn} = {
        extraConfig = ''
          root * /var/www/${fqdn}
          file_server
        '';
      };
    };

    services.borgbackup.jobs.${config.networking.hostName} = {
      paths = ["/var/lib/caddy"];
      exclude = [
        "/var/lib/caddy/**/locks"
        "/var/lib/caddy/**/challenge_tokens"
        "/var/lib/caddy/**/instance.uuid"
      ];
    };
    systemd.tmpfiles.rules = [
      "d /var/www/${fqdn} 0755 caddy caddy -"
    ];
  };
}
