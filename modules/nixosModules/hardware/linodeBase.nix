{inputs, ...}: {
  flake.nixosModules.linodeBase = {
    config,
    lib,
    modulesPath,
    pkgs,
    ...
  }: {
    imports = [
      (modulesPath + "/profiles/qemu-guest.nix")
    ];

    boot = {
      kernelPackages = pkgs.linuxPackages;
      kernelModules = [
        "virtio_net"
      ];

      kernelParams = ["console=ttyS0,19200n8"];
      loader = {
        timeout = 0;
        grub = {
          enable = true;
          device = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi-disk-0";

          extraConfig = ''
            serial --speed 19200 --unit=0 --word=8 --parity=no --stop=1;
            terminal_input serial;
            terminal_output serial
          '';
        };
      };
    };

    networking = {
      networkmanager.enable = false;
      usePredictableInterfaceNames = false;
      useDHCP = true;
      tempAddresses = "disabled";
    };

    environment.systemPackages = with pkgs; [
      htop
      kexec-tools
      mtr
      screen
      sysstat
      traceroute
    ];
  };
}
