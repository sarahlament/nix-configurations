{ ... }:
{
  flake.diskoConfigurations = {
    # BIOS-only Linode (Direct Disk), so GPT with a 1M bios_grub (EF02) partition
    # for GRUB's core.img - no UEFI/ESP. ext4 /boot keeps the bootloader off btrfs
    # entirely (GRUB's btrfs support is finicky). Root is tmpfs; /nix + /persist +
    # /var/log are btrfs subvols, mirroring uefi-plain. GPT (not msdos) because disko
    # deprecated the legacy table type. Linode-specific (by-id scsi paths, two-disk
    # split); if Linode ever ships UEFI the disks look the same minus the bios_grub.
    bios-linode.disko.devices = {
      disk = {
        linode-root = {
          device = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi-disk-0";
          type = "disk";
          content = {
            type = "gpt";
            partitions = {
              bios = {
                type = "EF02"; # BIOS boot partition - holds GRUB core.img on GPT
                size = "1M";
              };
              boot = {
                size = "1G";
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/boot";
                };
              };
              root = {
                size = "100%";
                content = {
                  type = "btrfs";
                  subvolumes = {
                    "@nix" = {
                      mountpoint = "/nix";
                      mountOptions = [
                        "nodatacow"
                        "noatime"
                      ];
                    };
                    "@persist" = {
                      mountpoint = "/persist";
                      mountOptions = [
                        "nodatacow"
                        "noatime"
                      ];
                    };
                    "@log" = {
                      mountpoint = "/var/log";
                      mountOptions = [
                        "nodatacow"
                        "noatime"
                      ];
                    };
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
      nodev = {
        "/" = {
          fsType = "tmpfs";
          mountOptions = [
            "size=512M"
            "mode=755"
          ];
        };
      };
    };
  };
}
