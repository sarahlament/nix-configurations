{
  config,
  lib,
  pkgs,
  self,
  ...
}:
let
  inherit (self.myLib.directory.hosts.${config.networking.hostName}.ip) internal;

  # node exporter (from system/base/monitoring.nix) already runs here and is
  # already scraped by minerva. rather than stand up a second exporter for the
  # speedtest, a timer drops a .prom file into this dir and node exporter's
  # textfile collector serves it - so the throughput metrics ride the existing
  # scrape with zero changes on minerva. world-readable + owned by a dedicated
  # user because node exporter is a DynamicUser and can't reach into another
  # service's StateDirectory (/var/lib/private is 0700).
  textfileDir = "/var/lib/node-exporter-textfile";

  # JSON is valid YAML, so this is a blackbox config. icmp pins v4 (the probe
  # targets are the gateway and public anchors); http_2xx is left v6-preferred
  # with fallback, which is what the internal service addresses want.
  blackboxConfig = pkgs.writeText "blackbox.yml" (
    builtins.toJSON {
      modules = {
        icmp = {
          prober = "icmp";
          timeout = "5s";
          icmp.preferred_ip_protocol = "ip4";
        };
        http_2xx = {
          prober = "http";
          timeout = "5s";
          http.fail_if_not_ssl = true;
        };
      };
    }
  );

  reportScript = pkgs.writeShellApplication {
    name = "speedtest-report";
    runtimeInputs = with pkgs; [
      librespeed-cli
      jq
      coreutils
    ];
    text = ''
      # a flaky run must not fail the unit or wipe the last good sample - just
      # leave the previous .prom in place and try again next tick.
      out=$(librespeed-cli --json) || { echo "librespeed run failed" >&2; exit 0; }

      # write + rename WITHIN textfileDir so the collector only ever sees a
      # complete file; the .XXXXXX temp name lacks the .prom suffix it scrapes.
      tmp=$(mktemp -p "${textfileDir}" .librespeed.XXXXXX)
      jq -r '
        "# HELP librespeed_download_mbps Download throughput (Mbit/s).",
        "# TYPE librespeed_download_mbps gauge",
        "librespeed_download_mbps \(.download)",
        "# HELP librespeed_upload_mbps Upload throughput (Mbit/s).",
        "# TYPE librespeed_upload_mbps gauge",
        "librespeed_upload_mbps \(.upload)",
        "# HELP librespeed_ping_ms Latency to the test server (ms).",
        "# TYPE librespeed_ping_ms gauge",
        "librespeed_ping_ms \(.ping)",
        "# HELP librespeed_jitter_ms Jitter to the test server (ms).",
        "# TYPE librespeed_jitter_ms gauge",
        "librespeed_jitter_ms \(.jitter)"
      ' <<<"$out" > "$tmp"
      mv -f "$tmp" "${textfileDir}/librespeed.prom"
    '';
  };
in
{
  users.users.speedtest = {
    isSystemUser = true;
    group = "speedtest";
  };
  users.groups.speedtest = { };

  services.prometheus.exporters = {
    # active network probing - the reason this box is on the home LAN. bound to
    # the WG address like node exporter, so minerva reaches it over the tunnel
    # and it's never exposed on wlan0.
    blackbox = {
      enable = true;
      listenAddress = "[${internal}]";
      port = 9115;
      configFile = blackboxConfig;
    };
    # extend the base node exporter (systemd collector) with the textfile
    # collector; enabledCollectors is a list, so this merges rather than replaces.
    node = {
      enabledCollectors = [ "textfile" ];
      extraFlags = [ "--collector.textfile.directory=${textfileDir}" ];
    };
  };

  systemd = {
    tmpfiles.rules = [ "d ${textfileDir} 0755 speedtest speedtest -" ];

    services.speedtest-report = {
      description = "LibreSpeed throughput probe -> node exporter textfile";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = "speedtest";
        Group = "speedtest";
        ExecStart = lib.getExe reportScript;
        ProtectSystem = "strict";
        ReadWritePaths = [ textfileDir ];
        NoNewPrivileges = true;
      };
    };

    timers.speedtest-report = {
      description = "Run the LibreSpeed probe every 30 min";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "5min";
        OnUnitActiveSec = "30min";
        Persistent = true;
      };
    };
  };
}
