{
  config,
  lib,
  pkgs,
  ...
}: {
  boot.blacklistedKernelModules = [
    "pcspkr" # annoying TTY beeps
  ];

  environment.systemPackages = with pkgs; [
    efibootmgr # Helper for EFI things
    modprobed-db # Track kernel module usage for optimization
    lshw # Comprehensive hardware info viewer
    pciutils # Provides 'lspci'
    usbutils # Provides 'lsusb'
    inxi # Fancy neo-fetch like hardware info viewer
  ];

  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_zen;
  boot.kernelParams = [
    "quiet"
    "nowatchdog"
    "zswap.enabled=1"
    "zswap.compressor=lz4"
    "zswap.max_pool_percent=20"
    "zswap.shrinker_enabled=1"
  ];
}
