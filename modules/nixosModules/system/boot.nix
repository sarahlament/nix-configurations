{inputs, ...}: {
  flake.nixosModules.boot = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) mkEnableOption mkDefault mkIf optionals;
    cfg = config.modules.boot;
  in {
    options.modules.boot = {
      desktop.enable = mkEnableOption "Enable extra module options for desktop";
      efi.enable = mkEnableOption "Enable EFI";
      zswap.enable = mkEnableOption "Enable zswap";
      zram.enable = mkEnableOption "Enable zram";
    };

    config = {
      boot = {
        loader = mkIf cfg.efi.enable {
          systemd-boot.enable = true;
          efi.canTouchEfiVariables = true;
          efi.efiSysMountPoint = "/efi";
        };

        initrd = {
          systemd.enable = true;
          availableKernelModules =
            [
              "ahci"
              "sd_mod"
            ]
            ++ (optionals cfg.desktop.enable) [
              "btrfs"
              "nvme"
              "xhci_pci"
              "usb_storage"
              "usbhid"
              "sr_mod"
            ]
            ++ (optionals cfg.zswap.enable) [
              "lz4"
              "lz4_compress"
            ];
        };
        blacklistedKernelModules = [
          "pcspkr" # annoying TTY beeps
        ];

        kernelPackages = mkDefault pkgs.linuxPackages_zen;
        kernelParams =
          [
            "nowatchdog"
          ]
          ++ (optionals cfg.zswap.enable) [
            "zswap.enabled=1"
            "zswap.compressor=lz4"
            "zswap.max_pool_percent=20"
            "zswap.shrinker_enabled=1"
          ]
          ++ (optionals cfg.desktop.enable) ["quiet"];
      };

      zramSwap.enable = mkIf cfg.zram.enable true;

      hardware.enableRedistributableFirmware = true;

      environment.systemPackages = with pkgs; [
        efibootmgr # Helper for EFI things
        modprobed-db # Track kernel module usage for optimization
        lshw # Comprehensive hardware info viewer
        pciutils # Provides 'lspci'
        usbutils # Provides 'lsusb'
      ];
    };
  };
}
