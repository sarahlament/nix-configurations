{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.atelier.kits.virtualisation;
in {
  options.atelier.kits.virtualisation = {
    enable = mkEnableOption "Virtualisation kit";
  };
  config = mkIf cfg.enable {
    programs.virt-manager.enable = true;
    virtualisation.libvirtd.enable = true;
    virtualisation.libvirtd.qemu.vhostUserPackages = with pkgs; [virtiofsd];
    virtualisation.spiceUSBRedirection.enable = true;

    home-manager.sharedModules = [
      {
        dconf.settings = {
          "org/virt-manager/virt-manager/connections" = {
            autoconnect = ["qemu:///system"];
            uris = ["qemu:///system"];
          };
        };
      }
    ];
  };
}
