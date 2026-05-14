{
  config,
  lib,
  pkgs,
  ...
}: {
  services.headscale.settings.dns.extra_records = [
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
}
