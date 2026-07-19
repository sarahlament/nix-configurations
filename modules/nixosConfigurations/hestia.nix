{
  inputs,
  self,
  ...
}:
let
  inherit (self.myLib.helpers) serviceModulesFor roleModulesFor;
  hostName = "hestia";
  activeModules =
    with self.nixosModules;
    [
      core
      disko
      lanzaboote
    ]
    ++ serviceModulesFor hostName
    ++ roleModulesFor hostName;
in
{
  # headless appliance, so nixpkgs-small like athena/minerva. lanzaboote because
  # secure boot is the trust marker for hosts under physical control (ishtar,
  # brigid) - a laptop in the house qualifies; the Linode does not.
  flake.nixosConfigurations.hestia = inputs.nixpkgs-small.lib.nixosSystem {
    specialArgs = { inherit inputs self; };
    modules = activeModules ++ [
      (inputs.import-tree (self + "/static/hestia"))

      {
        networking = { inherit hostName; };
        system.stateVersion = "26.11";
        nixpkgs.hostPlatform = "x86_64-linux";

        modules = {
          boot.efi.enable = true;
          disko.layout = "uefi-laptop";
          # no borg subuser: as a network probe this box holds no state worth
          # backing up (metrics live in minerva's prometheus). sub4 stays free.
        };
      }
    ];
  };
}
