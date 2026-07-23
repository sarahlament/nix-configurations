{ self, ... }:
{
  imports = with self.nixosModules; [
    borgbackup
    linodeGuest
  ];

  modules = {
    boot.zram.enable = true;
    services.borg.subuser = "sub1";
    disko.layout = "bios-linode";
  };
}
