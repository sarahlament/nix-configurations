{
  config,
  lib,
  pkgs,
  ...
}: {
  programs = {
    gamescope = {
      args = [
        "--rt"
        "--fullscreen"
        "--hdr-enabled"
        "--hdr-debug-force-output"
        "--hdr-itm-enable"
        "--prefer-output DP-1"
        "-W2560 -H1440 -r165"
      ];
    };
    gamemode.settings = {
      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        gpu_device = 0;
      };
    };
  };

  environment.systemPackages = with pkgs; [
    vulkan-hdr-layer-kwin6
  ];
}
