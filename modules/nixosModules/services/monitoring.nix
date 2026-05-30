{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.monitoring = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (self.myLib.constants) fqdn;
    inherit (self.myLib.helpers) mkReverseProxy;
  in {
    sops.secrets.grafanaSecretKey = {
      owner = "grafana";
      group = "grafana";
    };

    environment.etc."alloy/config.alloy".text = ''
      loki.source.journal "journal" {
        forward_to = [loki.relabel.journal.receiver]
        max_age    = "12h"
        labels     = {
          job  = "systemd-journal",
          host = "athena",
        }
      }

      loki.relabel "journal" {
        forward_to = [loki.write.local.receiver]

        rule {
          source_labels = ["__journal__systemd_unit"]
          target_label  = "unit"
        }
      }

      loki.write "local" {
        endpoint {
          url = "http://127.0.0.1:3100/loki/api/v1/push"
        }
      }
    '';

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

      alloy = {
        enable = true;
        extraFlags = ["--disable-reporting"];
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
            job_name = "${config.networking.hostName}";
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
          news.news_feed_enabled = false;

          security.secret_key = "$__file{${config.sops.secrets.grafanaSecretKey.path}}";

          server = {
            root_url = "https://grafana.${fqdn}";
            domain = "grafana.${fqdn}";
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
              name = "Loki";
              type = "loki";
              access = "proxy";
              url = "http://127.0.0.1:3100";
            }
          ];
        };
      };
    };

    services.caddy.virtualHosts."https://grafana.${fqdn}".extraConfig = mkReverseProxy config.services.grafana.settings.server.http_port;
  };
}
