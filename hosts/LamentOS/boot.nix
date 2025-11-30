{
  config,
  pkgs,
  lib,
  ...
}: {
  boot = {
    # as lanzaboote uses its own thing, force systemd-boot to false
    loader.systemd-boot.enable = lib.mkForce false;
    lanzaboote = {
      enable = true;
      pkiBundle = "/persist/pki";
      configurationLimit = 5;
      settings = {
        console-mode = "max";
        timeout = 2;
      };
    };

    initrd.availableKernelModules = [
      "btrfs"
      "lz4"
      "lz4_compress"
      "nvme"
      "xhci_pci"
      "ahci"
      "usb_storage"
      "usbhid"
      "sd_mod"
      "sr_mod"
    ];

    kernelPackages = pkgs.linuxPackages_zen;
    kernelParams = [
      "quiet"
      "nowatchdog"
      "zswap.enabled=1"
      "zswap.compressor=lz4"
      "zswap.max_pool_percent=20"
      "zswap.shrinker_enabled=1"
    ];
  };
}
