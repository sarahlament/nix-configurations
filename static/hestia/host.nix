{ self, ... }:
{
  # lanzaboote because secure boot is the trust marker for hosts under physical
  # control (ishtar, brigid) - a laptop in the house qualifies; the Linode does
  # not. headless appliance otherwise, so nixpkgs-small (set in the directory).
  imports = [ self.nixosModules.lanzaboote ];

  modules = {
    boot.efi.enable = true;
    disko.layout = "uefi-laptop";
    # no borg subuser: as a network probe this box holds no state worth backing
    # up (metrics live in minerva's prometheus). sub4 stays free.
  };
}
