{inputs, ...}: {
  flake.nixosModules.gollum = {
    config,
    lib,
    pkgs,
    ...
  }: let
    fqdn = config.modules.services.caddy.fqdn;
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

    services.caddy.virtualHosts."http://notes.athena.ts" = {
      extraConfig = ''
        reverse_proxy localhost:${toString config.services.gollum.port}
      '';
    };
  };
}
