{
  config,
  lib,
  pkgs,
  ...
}: {
  sops.secrets.grafana-github-pat = {
    owner = "grafana";
    group = "grafana";
  };

  services.prometheus = {
    enable = true;
    port = 9090;

    exporters = {
      node = {
        enable = true;
        enabledCollectors = ["systemd"];
        port = 9100;
      };
    };

    scrapeConfigs = [
      {
        job_name = "athena";
        static_configs = [
          {
            targets = ["localhost:${toString config.services.prometheus.exporters.node.port}"];
          }
        ];
      }
    ];
  };

  services.grafana = {
    enable = true;
    declarativePlugins = with pkgs.grafanaPlugins; [
      grafana-github-datasource
    ];
    settings = {
      analytics.reporting_enabled = false;
      news.mews_feed_enabled = false;

      server = {
        root_url = "https://athena.ts.lament.gay:3000";
        domain = "athena.ts.lament.gay";
        http_addr = "100.64.0.1";
        http_port = 3000;
      };
    };

    provision = {
      enable = true;
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          access = "proxy";
          url = "http://127.0.0.1:${toString config.services.prometheus.port}";
          isDefault = true;
        }
        {
          name = "GitHub";
          type = "grafana-github-datasource";
          jsonData = {
            selectedAuthType = "personal-access-token";
          };
          secureJsonData = {
            accessToken = "$__file{${config.sops.secrets.grafana-github-pat.path}}";
          };
        }
      ];
    };
  };

  # Make Grafana wait for Tailscale interface to be up
  systemd.services.grafana = {
    after = ["tailscaled.service" "network-online.service"];
    wants = ["tailscaled.service" "network-online.target"];
  };
}
