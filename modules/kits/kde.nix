{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.atelier.kits.kde;
in {
  options.atelier.kits.kde = {
    enable = mkEnableOption "KDE (plasma6) kit";
  };
  config = mkIf cfg.enable {
    xdg.portal = {
      enable = true;
      extraPortals = [pkgs.kdePackages.xdg-desktop-portal-kde];
      xdgOpenUsePortal = true;
    };

    hardware.graphics.enable = true;
    services = {
      dbus.enable = true;
      xserver.enable = true;
      displayManager = {
        sddm = {
          enable = true;
          wayland.enable = true;
          wayland.compositor = "kwin";
          autoNumlock = true;
        };
        defaultSession = "plasma";
      };
      desktopManager.plasma6.enable = true;
      desktopManager.plasma6.enableQt5Integration = false;
    };

    environment.systemPackages = with pkgs; [
      haruna # Video player
      kdePackages.kcalc # Calculator
      kdePackages.filelight # Disk usage analyzer
      kdePackages.discover # Software center
      kdePackages.partitionmanager # Disk partitioning
      kdePackages.kde-gtk-config # Better handling of GNOME (dconf) settings
    ];
  };
}
