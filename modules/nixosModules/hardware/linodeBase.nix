{ self, ... }: {
  flake.nixosModules.linodeBase =
    {
      pkgs,
      ...
    }:
    {
      imports = [ self.nixosModules.virtualGuest ];

      boot = {
        kernelPackages = pkgs.linuxPackages;
        kernelModules = [
          "virtio_net"
        ];

        kernelParams = [ "console=ttyS0,19200n8" ];
        loader = {
          timeout = 0;
          grub = {
            enable = true;
            forceInstall = true;
            # device comes from disko (the bios_grub partition sets grub.devices);
            # setting it here too would duplicate the disk in mirroredBoots

            extraConfig = ''
              serial --speed 19200 --unit=0 --word=8 --parity=no --stop=1;
              terminal_input serial;
              terminal_output serial
            '';
          };
        };
      };

      networking = {
        usePredictableInterfaceNames = false;
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
