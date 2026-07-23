{ self, ... }:
{
  imports = with self.nixosModules; [
    lanzaboote
    virtualGuest
  ];

  modules = {
    boot.efi.enable = true;
    disko.layout = "uefi-plain";
  };
}
