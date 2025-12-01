{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf mkEnableOption mkDefault mkOption types;
  inherit (types) nullOr str;
  cfg = config.atelier.kits.desktop;
in {
  options.atelier.kits.desktop = {
    enable = mkEnableOption "Desktop kit";
    isLaptop = mkEnableOption "does the device have a battery";
    autoLogin.user = mkOption {
      type = nullOr str;
      default = null;
      description = "enable auto-login for a speficic user";
      example = "lament";
    };
  };

  config = mkIf cfg.enable {
    networking.networkmanager.enable = mkDefault true;
    fonts = {
      enableDefaultPackages = true;
      enableGhostscriptFonts = true;
    };
    services = {
      displayManager.autoLogin = mkIf (cfg.autoLogin.user != null) {
        enable = true;
        user = cfg.autoLogin.user;
      };
      tuned = {
        enable = true;
        ppdSettings.main = {
          default = "performance"; # Maps to "throughput-performance"
          battery_detection = cfg.isLaptop;
        };
      };
      flatpak.enable = true;
    };

    hardware.bluetooth.enable = true;

    environment.systemPackages = with pkgs; [
      wl-clipboard # Wayland clipboard utilities
      wl-clip-persist # Persistent clipboard for Wayland
      discord # Voice and text chat
    ];
  };
}
