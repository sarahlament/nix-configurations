{ ... }: {
  flake.nixosModules.gaming =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib) mkEnableOption mkIf optionals;
      cfg = config.modules.gaming;
    in
    {
      options.modules.gaming.hdr.enable = mkEnableOption "Enable HDR support";
      config = {
        services.ratbagd.enable = true;

        programs = {
          steam.enable = true;
          steam.protontricks.enable = true;
          gamescope = {
            enable = true;
            args = [
              "--rt"
              "--fullscreen"
            ]
            ++ optionals (cfg.hdr.enable) [ "--hdr-enabled" ];
            env = mkIf cfg.hdr.enable {
              "DXVK_HDR" = "1";
            };
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

        environment.systemPackages =
          with pkgs;
          [
            lsfg-vk # Lossless Scaling (FrameGen)
            r2modman # Mod manager for various games
            #ryubing-canary # Switch emulator
            prismlauncher # Minecraft profile manager
            discord # Voice and text chat
            headsetcontrol # Headset control utility
            mangohud # Gaming performance overlay
            piper # Mouse configuration tool
            playerctl # Media player controller
            gamescope-wsi # WSI for gamescope. unsure why it's not included by default
          ]
          ++ optionals (cfg.hdr.enable) [ vulkan-hdr-layer-kwin6 ];
      };
    };
}
