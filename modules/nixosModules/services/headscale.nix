{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.headscale = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (self.myLib.constants) fqdn;
    inherit (self.myLib.helpers) mkSopsFile;
    inherit (self.myLib.constants.addresses) tailnet;
    inherit (config.networking) hostName;
  in {
    networking = {
      firewall.allowedTCPPorts = [3478];
      firewall.allowedUDPPorts = [3478];
    };

    services.caddy.virtualHosts."headscale.${fqdn}" = {
      extraConfig = ''
        reverse_proxy localhost:${toString config.services.headscale.port} {
          header_up Host {upstream_hostport}
          header_up X-Real-IP {remote_host}
        }
      '';
    };

    services.borgbackup.jobs.${config.networking.hostName}.paths = ["/var/lib/headscale"];

    sops.secrets = {
      "${hostName}Noise" = {
        sopsFile = mkSopsFile "services";
        owner = config.services.headscale.user;
      };
      "${hostName}DERP" = {
        sopsFile = mkSopsFile "services";
        owner = config.services.headscale.user;
      };
    };
    services.headscale = {
      enable = true;
      address = "127.0.0.1";
      port = 8080;

      settings = {
        server_url = "https://headscale.${fqdn}";
        noise.private_key_path = config.sops.secrets."${hostName}Noise".path;
        ephemeral_node_inactivity_timeout = "30m";
        logtail.enabled = false;
        database = {
          type = "sqlite3";
          sqlite.path = "/var/lib/headscale/db.sqlite";
        };

        dns = {
          base_domain = tailnet.domain;
          magic_dns = true;
          nameservers.global = ["1.1.1.1" "9.9.9.9"];
          override_local_dns = false;
        };
        prefixes = {
          inherit (self.myLib.constants.addresses.tailnet) v4 v6;
        };

        derp = {
          server = {
            enabled = true;
            region_id = 999;
            region_code = hostName;
            region_name = "${hostName} Embedded DERP";
            private_key_path = config.sops.secrets."${hostName}DERP".path;
            stun_listen_addr = "0.0.0.0:3478";
          };
          urls = ["https://controlplane.tailscale.com/derpmap/default"];
          auto_update_enabled = true;
          update_frequency = "24h";
        };
      };
    };
  };
}
