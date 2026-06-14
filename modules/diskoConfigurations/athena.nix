{inputs, ...}: {
  flake.diskoConfigurations = {
    athena.disko.devices = {
      disk = {
        linode-root = {
          device = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi-disk-0";
          type = "disk";
          content = {
            type = "gpt";
            partitions = {
              bios = {
                size = "1M";
                type = "EF02";
              };
              boot = {
                size = "1G";
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/boot";
                };
              };
              root = let
                mntopts = ["compress=zstd" "noatime"];
              in {
                size = "100%";
                type = "btrfs";
                extraArgs = ["-f"];
                subvolumes = {
                  "@" = {
                    mountpoint = "/";
                    mountOptions = mntopts;
                  };
                  "@nix" = {
                    mountpoint = "/nix";
                    mountOptions = mntopts;
                  };
                  "@persist" = {
                    mountpoint = "/persist";
                    mountOptions = mntopts;
                  };
                  "@home" = {
                    mountpoint = "/home";
                    mountOptions = mntopts;
                  };
                  "@log" = {
                    mountpoint = "/var/log";
                    mountOptions = mntopts;
                  };
                };
              };
            };
          };
        };
        linode-swap = {
          device = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi-disk-1";
          type = "disk";
          content = {
            type = "swap";
          };
        };
      };
    };
  };
}
