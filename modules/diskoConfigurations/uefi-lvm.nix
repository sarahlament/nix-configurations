{ ... }: {
  flake.diskoConfigurations = {
    # desktop (ishtar): UEFI + LVM, tmpfs root (impermanent). @home/@nix/@persist +
    # @log survive; / is wiped every boot. No LUKS yet - graduates to a uefi-luks
    # layout when the encryption rework lands.
    uefi-lvm.disko.devices = {
      disk = {
        system = {
          device = "/dev/disk/by-id/nvme-WD_BLACK_SN770_1TB_23396D803695";
          type = "disk";
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                type = "EF00";
                size = "2G";
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
              NIXOS = {
                size = "100%";
                content = {
                  type = "lvm_pv";
                  vg = "ishtar";
                };
              };
            };
          };
        };
      };
      lvm_vg = {
        ishtar = {
          type = "lvm_vg";
          lvs = {
            swap = {
              size = "38G";
              content = {
                type = "swap";
                resumeDevice = true;
              };
            };
            system = {
              size = "100%";
              content = {
                type = "btrfs";
                subvolumes = {
                  "@home" = {
                    mountpoint = "/home";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                  "@nix" = {
                    mountpoint = "/nix";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                  "@persist" = {
                    mountpoint = "/persist";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                  # nodatacow to match the rest of the fleet's @log - append-heavy
                  # journald churns CoW into fragmentation
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
