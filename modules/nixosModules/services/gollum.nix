{ self, ... }: {
  flake.nixosModules.gollum =
    { config, ... }:
    let
      inherit (self.myLib.constants) fqdn;
      inherit (self.myLib.helpers) mkPrivateProxy;
      inherit (self.myLib.directory.hosts.${config.networking.hostName}) ip;
    in
    {
      services.gollum = {
        enable = true;
        address = "localhost";
        port = 4567;

        extraConfig = ''
          wiki_options = {
            show_local_time: true
          };

          Precious::App.set(:wiki_options, wiki_options)
        '';
      };
      services.caddy.virtualHosts."https://notes.${fqdn}".extraConfig =
        mkPrivateProxy ip.internal config.services.gollum.port;
    };
}
