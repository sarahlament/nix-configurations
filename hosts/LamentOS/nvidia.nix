{
  config,
  lib,
  pkgs,
  ...
}: {
  services.xserver.videoDrivers = ["nvidia"];
  boot.initrd.kernelModules = ["nvidia"];

  services.udev.extraRules = ''
    KERNEL=="card*", SUBSYSTEM=="drm", GROUP="video", MODE="0660"
    KERNEL=="renderD*", SUBSYSTEM=="drm", GROUP="video", MODE="0660"
  '';

  hardware.nvidia = {
    open = true;
    modesetting.enable = true;
    package = config.boot.kernelPackages.nvidiaPackages.beta;
    nvidiaPersistenced = true;
    powerManagement = {
      enable = true;
      finegrained = false;
    };
  };
  hardware.nvidia-container-toolkit.enable = true;

  home-manager.sharedModules = [
    {
      home.sessionVariables = {
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
        ELECTRON_OZONE_PLATFORM_HINT = "auto";
        GBM_BACKEND = "nvidia-drm";
        LIBVA_DRIVER_NAME = "nvidia";
        VDPAU_DRIVER = "nvidia";
      };
    }
  ];
}
