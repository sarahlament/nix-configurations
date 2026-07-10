{ ... }: {
  flake.nixosModules.virtualGuest =
    { modulesPath, pkgs, ... }:
    {
      imports = [
        (modulesPath + "/profiles/qemu-guest.nix")
      ];
      boot = {
        kernelPackages = pkgs.linuxPackages;
        kernelModules = [ "virtio_net" ];
      };

      services.qemuGuest.enable = true;
    };
}
