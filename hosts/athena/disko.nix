{
  config,
  lib,
  pkgs,
  ...
}: {
  disko.devices = {
    disk = {
      linode-root = {
        device = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi-disk-0";
        type = "disk";
        content = {
          type = "filesystem";
          format = "ext4";
          mountpoint = "/";
        };
      };
      linide-swap = {
        device = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi-disk-1";
        type = "disk";
        content = {
          type = "swap";
        };
      };
    };
  };
}
