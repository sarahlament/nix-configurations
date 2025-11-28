{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf mkEnableOption mkOption types;
  cfg = config.atelier.kits.desktop;
in {
  options.atelier.kits.desktop = {
    enable = mkEnableOption "Desktop kit";
    isLaptop = mkEnableOption "does the device have a battery";
    autoLogin.user = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "enable auto-login for a speficic user";
      example = "lament";
    };
  };

  config = mkIf cfg.enable {
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
