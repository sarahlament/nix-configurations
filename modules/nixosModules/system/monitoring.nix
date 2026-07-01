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
    inherit (config.networking) hostName;
    inherit (self.myLib.directory) hosts;
    inherit (self.myLib.directory.hosts.${hostName}.ip) internal;
    monitor =
      lib.findFirst (host: host.roles.monitor or false)
      (throw "network: no monitor defined in directory")
      (lib.attrValues hosts);
  in {
    environment.etc."alloy/config.alloy".text = ''
      loki.source.journal "journal" {
        forward_to    = [loki.write.local.receiver]
        max_age       = "12h"
        relabel_rules = loki.relabel.journal.rules
        labels        = {
          job  = "systemd-journal",
          host = "${config.networking.hostName}",
        }
      }

      loki.relabel "journal" {
        forward_to = []
        rule {
          source_labels = ["__journal__systemd_unit"]
          target_label  = "service_name"
        }

        rule {
          source_labels = ["service_name"]
          regex         = "(.+)\\.service"
          replacement   = "$1"
          target_label  = "service_name"
        }

        rule {
          source_labels = ["service_name", "__journal_syslog_identifier"]
          separator     = ";"
          regex         = ";(.+)"
          replacement   = "$1"
          target_label  = "service_name"
        }
      }

      loki.write "local" {
        endpoint {
          url = "http://[${monitor.ip.internal}]:3100/loki/api/v1/push"
        }
      }
    '';

    services = {
      alloy = {
        enable = true;
        extraFlags = ["--disable-reporting"];
      };
      prometheus.exporters = {
        node = {
          enable = true;
          listenAddress = "[${internal}]";
          enabledCollectors = ["systemd"];
          port = 9100;
        };
      };
    };
  };
}
