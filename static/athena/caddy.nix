{
  config,
  self,
  ...
}: {
  services.caddy.virtualHosts = let
    inherit (self.myLib) mkReverseProxy;
  in {
    "http://notes.athena.ts".extraConfig = mkReverseProxy config.services.gollum.port;
    "http://grafana.athena.ts".extraConfig = mkReverseProxy config.services.grafana.settings.server.http_port;
  };
}
