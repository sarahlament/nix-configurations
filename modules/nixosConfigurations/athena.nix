{
  inputs,
  self,
  ...
}: let
  activeModules = with self.nixosModules; [
    core
    disko
    linodeBase

    caddy
    forgejo
    gollum
    headscale
    kresd
    mailserver
    monitoring
    vaultwarden
  ];
in {
  flake.nixosConfigurations.athena = inputs.nixpkgs-small.lib.nixosSystem {
    specialArgs = {inherit inputs self;};
    modules =
      activeModules
      ++ [
        (inputs.import-tree (self + "/static/athena"))

        {
          networking.hostName = "athena";
          system.stateVersion = "26.05";
          nixpkgs.hostPlatform = "x86_64-linux";

          modules.boot.zram.enable = true;
          modules.services.borg.subuser = "sub1";
        }
      ];
  };
}
