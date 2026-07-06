{ self, ... }: {
  flake.nixosModules.grafana =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (self.myLib.constants) fqdn;
      inherit (self.myLib.helpers) mkSopsFile;
      inherit (self.myLib.directory) hosts;
      inherit (hosts.${config.networking.hostName}.ip) internal;
    in
    {
      # all three run as static users with state under /var/lib. the persist entry
      # must carry the owning user/group - a plain string persists as root:root, and
      # the bind mount then locks the service out of its own StateDirectory.
      environment.persistence."/persist".directories = [
        {
          directory = "/var/lib/loki";
          user = "loki";
          group = "loki";
        }
        {
          directory = "/var/lib/prometheus2";
          user = "prometheus";
          group = "prometheus";
        }
        {
          directory = "/var/lib/grafana";
          user = "grafana";
          group = "grafana";
        }
      ];

      sops.secrets.grafanaSecretKey = {
        sopsFile = mkSopsFile "services";
        owner = "grafana";
      };

      services = {
        loki = {
          enable = true;
          configuration = {
            auth_enabled = false;

            server.http_listen_port = 3100;
            common = {
              instance_addr = "127.0.0.1";
              ring.kvstore.store = "inmemory";
              replication_factor = 1;
            };
            ingester = {
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
              # without these the compactor only compacts; retention_period is just a query limit
              retention_enabled = true;
              delete_request_store = "filesystem";
            };

            limits_config = {
              retention_period = "744h"; # 31 days
              reject_old_samples = true;
              reject_old_samples_max_age = "168h";
            };
          };
        };

        prometheus = {
          enable = true;
          port = 9090;

          scrapeConfigs = [
            {
              job_name = "nodes";
              static_configs = lib.mapAttrsToList (name: host: {
                targets = [ "[${host.ip.internal}]:9100" ];
                labels.host = name;
              }) hosts;
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
              http_addr = internal;
              http_port = self.myLib.directory.services.grafana.port;
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
    };
}
