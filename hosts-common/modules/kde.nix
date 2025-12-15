{
  config,
  lib,
  pkgs,
  ...
}: {
  options.kde.enable = lib.mkEnableOption "Enable KDE";
  config = lib.mkIf config.kde.enable {
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
