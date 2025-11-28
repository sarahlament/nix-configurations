{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.atelier.kits.gaming;
in {
  options.atelier.kits.gaming = {
    enable = mkEnableOption "Gaming kit";
  };

  config = mkIf cfg.enable {
    services.ratbagd.enable = true;

    programs.steam.enable = true;
    programs.gamescope = {
      enable = true;
      env = {
        WLR_RENDERER = "vulkan";
        SDL_VIDEODRIVER = "x11";
      };
      args = ["--expose-wayland"];
    };
    programs.gamemode = {
      enable = true;
      settings = {
        gpu = {
          apply_gpu_optimisations = "accept-responsibility";
          gpu_device = 0;
        };
      };
    };

    environment.systemPackages = with pkgs; [
      headsetcontrol # Headset control utility
      mangohud # Gaming performance overlay
      piper # Mouse configuration tool
      playerctl # Media player controller
      pwvucontrol # PipeWire volume control
    ];
  };
}
