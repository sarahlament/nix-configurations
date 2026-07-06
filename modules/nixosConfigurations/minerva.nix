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
    virtualGuest
  ];
  serviceModules = self.myLib.helpers.serviceModulesFor "minerva";
in
{
  flake.nixosConfigurations.minerva = inputs.nixpkgs-small.lib.nixosSystem {
    specialArgs = { inherit inputs self; };
    modules =
      activeModules
      ++ serviceModules
      ++ [
        {
          networking.hostName = "minerva";
          system.stateVersion = "26.11";
          nixpkgs.hostPlatform = "x86_64-linux";

          modules = {
            boot.efi.enable = true;
            services.borg.subuser = "sub3";
          };

          # sops reads its key from /persist/key.age before secrets decrypt
          fileSystems."/persist".neededForBoot = true;
        }
      ];
  };
}
