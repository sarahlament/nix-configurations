{
  inputs,
  self,
  ...
}:
let
  activeModules = with self.nixosModules; [
    core
    disko
    lanzaboote
    nvidia

    pipewire
    forgejo-runner
    stylix

    develop
    gaming
    kde
    workstation
  ];
  serviceModules = self.myLib.helpers.serviceModulesFor "ishtar";
in
{
  flake.nixosConfigurations.ishtar = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = { inherit inputs self; };
    modules =
      activeModules
      ++ serviceModules
      ++ [
        (inputs.import-tree (self + "/static/ishtar"))

        {
          networking.hostName = "ishtar";
          system.stateVersion = "26.05";
          nixpkgs.hostPlatform = "x86_64-linux";

          modules = {
            boot.desktop.enable = true;
            boot.zswap.enable = true;
            services.borg.subuser = "sub2";
            lament.desktop.enable = true;
            stylix.wallpaper = true;
          };

          fileSystems."/persist".neededForBoot = true;

          # the CC plugin doesn't like me :L
          programs.nix-ld.enable = true;
        }
      ];
  };
}
