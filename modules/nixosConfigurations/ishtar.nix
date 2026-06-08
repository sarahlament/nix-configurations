{
  inputs,
  self,
  ...
}: let
  activeModules = with self.nixosModules; [
    core
    disko
    lanzaboote
    nvidia

    pipewire
    stylix

    forgejo-runner

    develop
    gaming
    kde
    workstation
  ];
in {
  flake.nixosConfigurations.ishtar = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = {inherit inputs self;};
    modules =
      activeModules
      ++ [
        (inputs.import-tree (self + "/static/ishtar"))

        {
          networking.hostName = "ishtar";
          system.stateVersion = "26.05";
          nixpkgs.hostPlatform = "x86_64-linux";

          modules.boot.desktop.enable = true;
          modules.boot.zswap.enable = true;
          modules.lament.desktop.enable = true;
          modules.stylix.wallpaper = true;
        }
      ];
  };
}
