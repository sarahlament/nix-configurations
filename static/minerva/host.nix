{ self, ... }:
{
  imports = with self.nixosModules; [
    borgbackup
    lanzaboote
    virtualGuest
  ];

  modules = {
    boot.efi.enable = true;
    services.borg.subuser = "sub3";
    disko.layout = "uefi-plain";
  };
}
