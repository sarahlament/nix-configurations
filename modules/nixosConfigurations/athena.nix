{
  inputs,
  self,
  ...
}:
let
  inherit (self.myLib.helpers) serviceModulesFor roleModulesFor;
  hostName = "athena";
  activeModules =
    with self.nixosModules;
    [
      core
      disko
      linodeGuest
    ]
    ++ serviceModulesFor hostName
    ++ roleModulesFor hostName;
in
{
  flake.nixosConfigurations.athena = inputs.nixpkgs-small.lib.nixosSystem {
    specialArgs = { inherit inputs self; };
    modules = activeModules ++ [
      (inputs.import-tree (self + "/static/athena"))

      {
        networking = { inherit hostName; };
        system.stateVersion = "26.05";
        nixpkgs.hostPlatform = "x86_64-linux";

        modules = {
          boot.zram.enable = true;
          services.borg.subuser = "sub1";
          disko.layout = "bios-linode";
        };
      }
    ];
  };
}
