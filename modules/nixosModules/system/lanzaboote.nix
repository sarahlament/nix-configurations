{ inputs, ... }: {
  flake.nixosModules.lanzaboote =
    {
      config,
      lib,
      ...
    }:
    {
      imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];

      services.borgbackup.jobs.${config.networking.hostName}.paths = [ "/persist/pki" ];
      boot = {
        loader = {
          systemd-boot.enable = lib.mkForce false;
          efi.canTouchEfiVariables = true;
          efi.efiSysMountPoint = "/efi";
        };
        lanzaboote = {
          enable = true;
          pkiBundle = "/persist/pki";
          configurationLimit = 3;
          settings = {
            console-mode = 0;
            timeout = 2;
          };
        };
      };
    };
}
