{ ... }: {
  flake.diskoConfigurations = {
    minerva.disko.devices = {
      disk = {
        system = {
          device = "/dev/vda"; # Proxmox virtio disk - confirm on the VM
          type = "disk";
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                type = "EF00"; # EFI system partition for OVMF/systemd-boot
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
            "size=2G"
            "mode=755"
          ];
        };
      };
    };
  };
}
