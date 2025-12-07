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

  services = {
    loki = {
      enable = true;
      configuration = {
        auth_enabled = false;

        server.http_listen_port = 3100;

        ingester = {
          lifecycler = {
            address = "127.0.0.1";
            ring = {
              kvstore.store = "inmemory";
              replication_factor = 1;
            };
          };
          chunk_idle_period = "5m";
          chunk_retain_period = "30s";
        };

        schema_config.configs = [
          {
            from = "2024-01-01";
            store = "tsdb";
            object_store = "filesystem";
            schema = "v13";
            index = {
              prefix = "index_";
              period = "24h";
            };
          }
        ];

        storage_config = {
          filesystem.directory = "/var/lib/loki/chunks";
          tsdb_shipper = {
            active_index_directory = "/var/lib/loki/tsdb-index";
            cache_location = "/var/lib/loki/tsdb-cache";
          };
        };

        compactor = {
          working_directory = "/var/lib/loki/compactor";
          compaction_interval = "10m";
        };

        limits_config = {
          retention_period = "744h"; # 31 days
          reject_old_samples = true;
          reject_old_samples_max_age = "168h";
        };

        table_manager = {
          retention_deletes_enabled = true;
          retention_period = "744h";
        };
      };
    };

    promtail = {
      enable = true;
      configuration = {
        server = {
          http_listen_port = 9080;
          grpc_listen_port = 0;
        };
        clients = [
          {
            url = "http://127.0.0.1:3100/loki/api/v1/push";
          }
        ];
        scrape_configs = [
          {
            job_name = "journal";
            journal = {
              max_age = "12h";
              labels = {
                job = "systemd-journal";
                host = "athena";
              };
            };
            relabel_configs = [
              {
                source_labels = ["__journal__systemd_unit"];
                target_label = "unit";
              }
            ];
          }
        ];
      };
    };

    prometheus = {
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

    grafana = {
      enable = true;
      declarativePlugins = with pkgs.grafanaPlugins; [
        grafana-github-datasource
        grafana-lokiexplore-app
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
          {
            name = "Loki";
            type = "loki";
            access = "proxy";
            url = "http://127.0.0.1:3100";
          }
        ];
      };
    };
  };

  # Make Grafana wait for Tailscale interface to be up
  systemd.services.grafana = {
    after = ["tailscaled.service" "network-online.target"];
    wants = ["tailscaled.service" "network-online.target"];
  };
}
