{
  config,
  pkgs,
  lib,
  ...
}: {
  # as lanzaboote uses its own thing, force systemd-boot to false
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/persist/pki";
    configurationLimit = 5;
    settings = {
      console-mode = "max";
      timeout = 2;
    };
  };

  boot.initrd.availableKernelModules = [
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
}
