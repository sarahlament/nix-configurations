{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.gollum = {
    config,
    lib,
    pkgs,
    ...
  }: let
    fqdn = config.modules.services.caddy.fqdn;
    inherit (self.myLib) mkReverseProxy;
  in {
    services.gollum = {
      enable = true;
      address = "localhost";

      extraConfig = ''
        wiki_options = {
          show_local_time: true
        };

        Precious::App.set(:wiki_options, wiki_options)
      '';
    };
    services.caddy.virtualHosts."https://notes.${fqdn}".extraConfig = mkReverseProxy config.services.gollum.port;
  };
}
