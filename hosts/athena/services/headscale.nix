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

      noise.private_key_path = "/var/lib/headscale/noise_private.key";

      database = {
        type = "sqlite3";
        sqlite.path = "/var/lib/headscale/db.sqlite";
      };

      dns = {
        base_domain = "ts";
        magic_dns = true;
        nameservers.global = ["1.1.1.1" "9.9.9.9"];
        extra_records = [
          {
            name = "git.athena.ts";
            type = "A";
            value = "100.64.0.1";
          }
          {
            name = "grafana.athena.ts";
            type = "A";
            value = "100.64.0.1";
          }
        ];
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
  systemd = {
    targets.tailnet-online = {
      description = "tailnet is online and connected";
      after = ["network-online.target" "tailscaled.service"];
      wants = ["network-online.target" "tailscaled.service"];
    };
    services = {
      tailnet-ready = {
        description = "check for tailnet connectivity";
        after = ["tailscaled.service"];
        wants = ["tailscaled.service"];
        wantedBy = ["tailnet-online.target"];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };

        script = ''
          # wait for tailnet to be up
          until ${pkgs.tailscale}/bin/tailscale status --json | \
              ${pkgs.jq}/bin/jq -e '.BackendState == "Running"'; do
            sleep 2
          done

          # wait for tailnet to have an IP
          until ${pkgs.iproute2}/bin/ip addr show tailscale0 | ${pkgs.gnugrep}/bin/grep -q '100\.'; do
            sleep 2
          done
        '';
      };
    };
  };
}
