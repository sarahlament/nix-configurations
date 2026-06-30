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
        forward_to = [loki.relabel.journal.receiver]
        max_age    = "12h"
        labels     = {
          job  = "systemd-journal",
          host = "${config.networking.hostName}",
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
