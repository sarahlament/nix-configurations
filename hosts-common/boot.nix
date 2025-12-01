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
  ];
}
