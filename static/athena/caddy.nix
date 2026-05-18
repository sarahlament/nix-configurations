{
  config,
  lib,
  pkgs,
  ...
}: {
  services.caddy.virtualHosts = let
    mkReverseProxy = port: ''reverse_proxy localhost:${toString port}'';
  in {
    "http://notes.athena.ts".extraConfig = mkReverseProxy config.services.gollum.port;
    "http://git.athena.ts".extraConfig = mkReverseProxy config.services.forgejo.settings.server.HTTP_PORT;
    "http://grafana.athena.ts".extraConfig = mkReverseProxy config.services.grafana.settings.server.http_port;
  };
}
