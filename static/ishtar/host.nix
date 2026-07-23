{ lib, self, ... }:
{
  imports = with self.nixosModules; [
    borgbackup
    lanzaboote
    nvidia

    pipewire

    develop
    gaming
    niri
    workstation
  ];

  modules = {
    boot.desktop.enable = true;
    boot.zswap.enable = true;
    services.borg.subuser = "sub2";
    lament.desktop.enable = true;
    # lament's HM is standalone here (homeConfigurations."lament@ishtar",
    # `just home`); the integrated NixOS HM path is skipped.
    lament.standalone = true;
    disko.layout = "uefi-lvm";
  };

  # nvf runs via standalone HM on ishtar (so nvim tweaks don't need a system
  # rebuild); disable the fleet-wide NixOS nvf that core pulls in.
  programs.nvf.enable = lib.mkForce false;

  # the CC plugin doesn't like me :L
  programs.nix-ld.enable = true;
}
