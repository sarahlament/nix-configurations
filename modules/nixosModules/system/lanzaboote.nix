{inputs, ...}: {
  flake.nixosModules.lanzaboote = {
    config,
    lib,
    pkgs,
    ...
  }: {
    imports = [inputs.lanzaboote.nixosModules.lanzaboote];
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
