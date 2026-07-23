{ ... }: {
  # LUKS-on-btrfs UEFI layout for the Proxmox virtio VMs that want disk-at-rest
  # encryption (verdandi). same shape as uefi-plain - unencrypted ESP, tmpfs root,
  # @nix/@persist/@log subvols - but the whole root partition is a LUKS container.
  #
  # unlock story is two-keyed: `askPassword` prompts at *format* time and that
  # passphrase becomes keyslot 0 - the permanent recovery key. a TPM2-sealed
  # keyslot is added *after* install with `systemd-cryptenroll` (it needs the real
  # TPM + a settled PCR7, so it can't be declarative). `tpm2-device=auto` in the
  # crypttab opts makes systemd-initrd try that TPM slot at boot, falling back to
  # the passphrase prompt when the seal doesn't match (or before enrollment).
  flake.diskoConfigurations.uefi-luks.disko.devices = {
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
                type = "luks";
                name = "cryptroot";
                # prompt for the passphrase at install; it stays as the recovery
                # keyslot. the TPM keyslot is enrolled by hand post-install.
                askPassword = true;
                settings = {
                  allowDiscards = true;
                  # systemd-initrd reads this from crypttab and tries the TPM slot
                  crypttabExtraOpts = [ "tpm2-device=auto" ];
                };
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
}
