{ inputs, self, ... }:
let
  inherit (self.myLib.helpers) serviceModulesFor roleModulesFor;
  hostName = "brigid";
  activeModules =
    with self.nixosModules;
    [
      core
      disko
      lanzaboote
      virtualGuest
    ]
    ++ serviceModulesFor hostName
    ++ roleModulesFor hostName;
in
{
  flake.nixosConfigurations.brigid = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = { inherit inputs self; };
    modules = activeModules ++ [
      {
        networking = { inherit hostName; };
        nixpkgs.hostPlatform = "x86_64-linux";
        system.stateVersion = "26.11";

        modules = {
          boot.efi.enable = true;
          disko.layout = "uefi-plain";
        };
      }
    ];
  };
}
