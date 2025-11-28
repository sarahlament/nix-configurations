{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkOption mkIf mkMerge types optionals;
  cfg = config.atelier.hardware.graphics;
in {
  options.atelier.hardware.graphics = {
    vendor = mkOption {
      type = types.enum [
        "nvidia"
        "intel"
        "amd"
        "headless"
      ];
      default = "headless";
      description = "Which graphics driver should we enable";
    };

    nvidia = {
      open = mkOption {
        type = types.bool;
        default = true;
        description = "Use the nvidia-open drivers";
      };
    };
    intel = {
      driver = mkOption {
        type = types.enum [
          "iHD"
          "i965"
        ];
        default = "iHD";
        description = "Which vaapi driver to use";
      };
    };
    amd = {
      driver = mkOption {
        type = types.enum [
          "radv"
          "amdvlk"
        ];
        default = "radv";
        description = "Which vulkan driver to use";
      };
    };
  };

  config = mkMerge [
    {
      hardware.graphics.enable = true;
      home-manager.sharedModules = [
        {
          home.sessionVariables = {
            ELECTRON_OZONE_PLATFORM_HINT = "auto";
          };
        }
      ];
    }
    (mkIf (cfg.vendor == "nvidia") {
      services.xserver.videoDrivers = ["nvidia"];
      boot.initrd.kernelModules = ["nvidia"];

      hardware.nvidia = {
        open = cfg.nvidia.open;
        modesetting.enable = true;
        package = config.boot.kernelPackages.nvidiaPackages.beta;
        nvidiaPersistenced = true;
        powerManagement = {
          enable = true;
          finegrained = false;
        };
      };

      home-manager.sharedModules = [
        {
          home.sessionVariables = {
            LIBVA_DRIVER_NAME = "nvidia";
            VDPAU_DRIVER = "nvidia";
            GBM_BACKEND = "nvidia-drm";
            __GLX_VENDOR_LIBRARY_NAME = "nvidia";
          };
        }
      ];
    })

    (mkIf (cfg.vendor == "intel") {
      services.xserver.videoDrivers = ["modesetting"];
      boot.initrd.kernelModules = ["i915"];

      environment.systemPackages = with pkgs; [
        (
          if cfg.intel.driver == "iHD"
          then intel-media-driver
          else intel-vaapi-driver
        )
      ];

      home-manager.sharedModules = [
        {
          home.sessionVariables = {
            LIBVA_DRIVER_NAME = cfg.intel.driver;
            VDPAU_DRIVER = "va_gl";
          };
        }
      ];
    })

    (mkIf (cfg.vendor == "amd") {
      services.xserver.videoDrivers = ["amdgpu"];
      boot.initrd.kernelModules = ["amdgpu"];

      environment.systemPackages = with pkgs; (optionals (cfg.amd.driver == "amdvlk") [amdvlk]);

      home-manager.sharedModules = [
        {
          home.sessionVariables = {
            LIBVA_DRIVER_NAME = "radeonsi";
            VDPAU_DRIVER = "radeonsi";
          };
        }
        (mkIf (cfg.amd.driver == "amdvlk") {
          home.sessionVariables = {
            AMD_VULKAN_ICD = "AMDVLK";
          };
        })
      ];
    })
  ];
}
