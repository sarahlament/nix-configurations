{
  config,
  lib,
  pkgs,
  ...
}: {
  programs = {
    gamescope = {
      args = [
        "--hdr-enabled"
        "--prefer-output DP-1"
        "-W2560 -H1440 -r165"
      ];
      env = {
        "DXVK_HDR" = "1";
      };
    };
    gamemode.settings = {
      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        gpu_device = 0;
      };
    };
  };

  fileSystems."/persist/gamedir" = {
    device = "/dev/disk/by-label/GAMEDIR";
    fsType = "ext4";
  };

  environment.systemPackages = with pkgs; [
    vulkan-hdr-layer-kwin6
  ];
}
