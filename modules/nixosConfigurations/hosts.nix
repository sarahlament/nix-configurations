{ inputs, self, ... }:
let
  inherit (self.myLib.helpers) serviceModulesFor roleModulesFor;
  # every host is assembled the same way: the universal `core`, whatever the
  # directory places on it (services + roles), its own `static/<name>/`, and the
  # two facts that can't be a module - the nixpkgs channel that evaluates it and
  # the stateVersion. everything else host-local lives in static/<name>/.
  mkHost =
    name: entry:
    inputs.${entry.channel or "nixpkgs-small"}.lib.nixosSystem {
      specialArgs = { inherit inputs self; };
      modules =
        [ self.nixosModules.core ]
        ++ serviceModulesFor name
        ++ roleModulesFor name
        ++ [ (inputs.import-tree (self + "/static/${name}")) ]
        ++ [
          {
            networking.hostName = name;
            nixpkgs.hostPlatform = "x86_64-linux";
            system.stateVersion = entry.stateVersion;
          }
        ];
    };
in
{
  flake.nixosConfigurations = builtins.mapAttrs mkHost self.myLib.directory.hosts;
}
