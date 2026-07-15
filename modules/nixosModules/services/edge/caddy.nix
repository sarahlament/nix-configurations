{ self, ... }: {
  flake.nixosModules.caddy =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (self.myLib.constants) fqdn;
      inherit (self.myLib.directory) hosts services;
      inherit (self.myLib.helpers) mkReverseProxy;
      inherit (config.networking) hostName;
      inherit (hosts.${hostName}) ip;

      serviceVhosts = lib.mapAttrs' (
        name: svc:
        lib.nameValuePair "${name}.${fqdn}" {
          extraConfig =
            lib.optionalString (svc ? extraConfig) "${svc.extraConfig}\n"
            + mkReverseProxy {
              host = hosts.${svc.backend}.ip.internal;
              inherit (svc) port;
              bindTo = if (svc.public or false) then null else ip.internal;
            };
        }
      ) services;
    in
    {
      imports = [ self.nixosModules.tsig ];

      networking.firewall.allowedTCPPorts = [
        80 # HTTP
        443 # HTTPS
      ];

      systemd.services.caddy.serviceConfig.EnvironmentFile = config.sops.templates.acmeTsig.path;
      services.caddy = {
        enable = true;
        package = pkgs.caddy.withPlugins {
          plugins = [ "github.com/caddy-dns/rfc2136@v1.0.0" ];
          hash = "sha256-i6hgT3ufiVz13f2Ruox7EPLhIDXSomA3T/4IFmoHJUo=";
        };

        globalConfig = ''
          acme_dns rfc2136 {
            key_name {env.RFC2136_TSIG_KEY}
            key_alg {env.RFC2136_TSIG_ALGORITHM}
            key {env.RFC2136_TSIG_SECRET}
            server {env.RFC2136_NAMESERVER}
          }
        '';
        virtualHosts = serviceVhosts // {
          ${fqdn} = {
            extraConfig = ''
              root * /var/www/${fqdn}
              file_server
            '';
          };
        };
      };

      services.borgbackup.jobs.${config.networking.hostName} = {
        paths = [ "/var/lib/caddy" ];
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
