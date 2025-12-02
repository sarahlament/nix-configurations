{
  config,
  lib,
  pkgs,
  ...
}: {
  config = {
    services.ratbagd.enable = true;

    programs = {
      steam.enable = true;
      gamescope = {
        enable = true;
        env = {
          WLR_RENDERER = "vulkan";
          SDL_VIDEODRIVER = "x11";
          DXVK_HDR = "1";
          ENABLE_GAMESCOPE_WSI = "1";
        };
        args = [
          "--expose-wayland"
          "--rt"
          "--fullscreen"
          "--hdr-enabled"
          "--hdr-itm-enable"
          "--prefer-output DP-1"
          "-W2560 -H1440 -r165"
        ];
      };
      gamemode = {
        enable = true;
        settings = {
          gpu = {
            apply_gpu_optimisations = "accept-responsibility";
            gpu_device = 0;
          };
        };
      };
    };

    fileSystems."/persist/gamedir" = {
      device = "/dev/disk/by-label/GAMEDIR";
      fsType = "ext4";
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
