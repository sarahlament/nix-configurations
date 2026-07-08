{
  inputs,
  self,
  ...
}:
let
  activeModules =
    with self.nixosModules;
    [
      core
      disko
      lanzaboote
      virtualGuest
    ]
    ++ self.myLib.helpers.serviceModulesFor "minerva";
in
{
  flake.nixosConfigurations.minerva = inputs.nixpkgs-small.lib.nixosSystem {
    specialArgs = { inherit inputs self; };
    modules = activeModules ++ [
      {
        networking.hostName = "minerva";
        system.stateVersion = "26.11";
        nixpkgs.hostPlatform = "x86_64-linux";

        modules = {
          boot.efi.enable = true;
          services.borg.subuser = "sub3";
        };
      }
    ];
  };
}
