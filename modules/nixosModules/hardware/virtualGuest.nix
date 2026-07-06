{ ... }: {
  flake.nixosModules.virtualGuest =
    { modulesPath, ... }:
    {
      imports = [
        (modulesPath + "/profiles/qemu-guest.nix")
      ];

      services.qemuGuest.enable = true;
    };
}
