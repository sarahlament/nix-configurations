{
  config,
  lib,
  pkgs,
  ...
}: {
  networking.firewall.allowedTCPPorts = [
    3478 # DERP (whatever tf that is lmfao)
  ];
  networking.firewall.allowedUDPPorts = [
    3478 # apparently it's needed for both TCP and UDP??
  ];

  services.caddy = {
    virtualHosts."headscale.lament.gay" = {
      extraConfig = ''
        reverse_proxy localhost:${toString config.services.headscale.port} {
          header_up Host {upstream_hostport}
          header_up X-Real-IP {remote_host}
        }
      '';
    };
  };

  services.headscale = {
    enable = true;
    address = "127.0.0.1";
    port = 8080;

    settings = {
      server_url = "https://headscale.lament.gay";

      database = {
        type = "sqlite3";
        sqlite.path = "/var/lib/headscale/db.sqlite";
      };

      dns = {
        base_domain = "ts.lament.gay";
        magic_dns = true;
        nameservers.global = ["1.1.1.1" "9.9.9.9"];
      };

      prefixes = {
        v4 = "100.64.0.0/10";
        v6 = "fd7a:115c:a1e0::/48";
      };

      derp = {
        server = {
          enabled = true;
          region_id = 999;
          region_code = "athena";
          region_name = "Athena Embedded DERP";
          stun_listen_addr = "0.0.0.0:3478";
        };
        urls = ["https://controlplane.tailscale.com/derpmap/default"];
        auto_update_enabled = true;
        update_frequency = "24h";
      };

      logtail.enabled = false;
      ephemeral_node_inactivity_timeout = "30m";
    };
  };
}
