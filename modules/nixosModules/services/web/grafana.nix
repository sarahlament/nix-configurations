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
      inherit (self.myLib.helpers) mkSopsFile roleHost;
      inherit (self.myLib.directory) hosts;
      inherit (hosts.${config.networking.hostName}.ip) internal;
      mailRelay =
        (roleHost [
          "edge"
          "mail"
        ]).ip.internal;

      # the blackbox exporter lives on hestia - the only always-on box inside the
      # home LAN, so the only vantage that can probe the gateway/WAN from where it
      # matters. prometheus reaches it over WG.
      # PARKED 2026-07-23: hestia powered off, pulled from the directory. these
      # probes ran through its exporter, so they're dead until it's back - restore
      # alongside hestia's directory entry.
      /*
        blackboxAddr = "[${hosts.hestia.ip.internal}]:9115";
        # multi-target pattern: rewrite each listed target into a
        # /probe?target=<t> call against hestia's blackbox, keeping the real
        # target as the instance label.
        blackboxRelabel = [
          {
            source_labels = [ "__address__" ];
            target_label = "__param_target";
          }
          {
            source_labels = [ "__param_target" ];
            target_label = "instance";
          }
          {
            target_label = "__address__";
            replacement = blackboxAddr;
          }
        ];
      */
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
            # PARKED 2026-07-23 with hestia (see the let-block): the blackbox jobs
            # ran through its home-LAN exporter. restore alongside hestia.
            /*
              # is the home link up, from inside the house: gateway reachability +
              # latency, and the WAN via public anchors.
              {
                job_name = "blackbox-icmp";
                metrics_path = "/probe";
                params.module = [ "icmp" ];
                scrape_interval = "1m";
                static_configs = [
                  {
                    targets = [
                      "192.168.1.1"
                      "1.1.1.1"
                      "8.8.8.8"
                    ];
                  }
                ];
                relabel_configs = blackboxRelabel;
              }
              # is each app reachable as seen from home - hestia resolves these
              # through athena's kresd, so this exercises the split-horizon path too.
              {
                job_name = "blackbox-http";
                metrics_path = "/probe";
                params.module = [ "http_2xx" ];
                scrape_interval = "1m";
                static_configs = [
                  { targets = map (name: "https://${name}.${fqdn}") (builtins.attrNames services); }
                ];
                relabel_configs = blackboxRelabel;
              }
            */
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

            smtp = {
              enabled = true;
              # relay over WireGuard to the mailserver's internal address; no auth
              # (trusted via mynetworks), NoStartTLS since the tunnel already encrypts
              host = "[${mailRelay}]:25";
              startTLS_policy = "NoStartTLS";
              from_address = "grafana@${fqdn}";
              from_name = "grafana";
            };

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
