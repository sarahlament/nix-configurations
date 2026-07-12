{
  inputs,
  self,
  ...
}:
let
  inherit (self.myLib.helpers) serviceModulesFor roleModulesFor;
  hostName = "minerva";
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
  flake.nixosConfigurations.minerva = inputs.nixpkgs-small.lib.nixosSystem {
    specialArgs = { inherit inputs self; };
    modules = activeModules ++ [
      {
        networking = { inherit hostName; };
        system.stateVersion = "26.11";
        nixpkgs.hostPlatform = "x86_64-linux";

        modules = {
          boot.efi.enable = true;
          services.borg.subuser = "sub3";
          disko.layout = "uefi-plain";
        };
      }
    ];
  };
}
