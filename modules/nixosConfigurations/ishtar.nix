{
  inputs,
  self,
  ...
}:
let
  inherit (self.myLib.helpers) serviceModulesFor roleModulesFor;
  hostName = "ishtar";
  activeModules =
    with self.nixosModules;
    [
      core
      disko
      lanzaboote
      nvidia

      pipewire

      develop
      gaming
      niri
      workstation
    ]
    ++ serviceModulesFor hostName
    ++ roleModulesFor hostName;
in
{
  flake.nixosConfigurations.ishtar = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = { inherit inputs self; };
    modules = activeModules ++ [
      (inputs.import-tree (self + "/static/ishtar"))

      {
        networking = { inherit hostName; };
        nixpkgs.hostPlatform = "x86_64-linux";
        system.stateVersion = "26.05";

        modules = {
          boot.desktop.enable = true;
          boot.zswap.enable = true;
          services.borg.subuser = "sub2";
          lament.desktop.enable = true;
          disko.layout = "uefi-lvm";
        };

        # the CC plugin doesn't like me :L
        programs.nix-ld.enable = true;
      }
    ];
  };
}
