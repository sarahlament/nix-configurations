{
  config,
  lib,
  pkgs,
  ...
}: {
  options.gaming.enable = lib.mkEnableOption "Gaming module";
  config = lib.mkIf config.gaming.enable {
    services.ratbagd.enable = true;

    programs = {
      steam.enable = true;
      gamescope = {
        enable = true;
      };
      gamemode = {
        enable = true;
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
      gamescope-wsi # WSI for gamescope. unsure why it's not included by default
    ];
  };
}
