{
  config,
  lib,
  pkgs,
  ...
}: {
  disko.devices = {
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
                mountOptions = ["dmask=0077" "fmask=0077"];
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
                "@" = {
                  mountpoint = "/";
                  mountOptions = ["compress=zstd" "noatime"];
                };
                "@home" = {
                  mountpoint = "/home";
                  mountOptions = ["compress=zstd" "noatime"];
                };
                "@nix" = {
                  mountpoint = "/nix";
                  mountOptions = ["compress=zstd" "noatime"];
                };
                "@persist" = {
                  mountpoint = "/persist";
                  mountOptions = ["compress=zstd" "noatime"];
                };
              };
            };
          };
        };
      };
    };
  };
}
