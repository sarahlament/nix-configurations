{ ... }: {
  flake.diskoConfigurations = {
    # bare-metal laptop (hestia): UEFI, no swap, tmpfs root. same shape as
    # uefi-plain, but on a real SATA disk rather than a Proxmox virtio one.
    uefi-laptop.disko.devices = {
      disk = {
        system = {
          device = "/dev/sda";
          type = "disk";
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                type = "EF00";
                size = "1G";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/efi";
                  mountOptions = [
                    "dmask=0077"
                    "fmask=0077"
                  ];
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
      };
      nodev = {
        "/" = {
          fsType = "tmpfs";
          mountOptions = [
            "size=4G"
            "mode=755"
          ];
        };
      };
    };
  };
}
