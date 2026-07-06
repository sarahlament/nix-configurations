{ self, ... }: {
  flake.nixosModules.gollum =
    { config, ... }:
    let
      inherit (self.myLib.directory.hosts.${config.networking.hostName}.ip) internal;
    in
    {
      services = {
        gollum = {
          enable = true;
          address = internal;
          inherit (self.myLib.directory.services.notes) port;

          extraConfig = ''
            wiki_options = {
              show_local_time: true
            };

            Precious::App.set(:wiki_options, wiki_options)
          '';
        };
        borgbackup.jobs.${config.networking.hostName}.paths = [
          config.services.gollum.stateDir
        ];
      };

      # static user, so its stateDir isn't under /var/lib/private. the persist entry
      # must own the dir too - a plain string lands root:root and the bind mount locks
      # gollum out of its own state on a fresh boot
      environment.persistence."/persist".directories = [
        {
          directory = config.services.gollum.stateDir;
          user = "gollum";
          group = "gollum";
        }
      ];
    };
}
