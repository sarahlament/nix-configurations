{
  config,
  inputs,
  ...
}: {
  imports = [
    inputs.disko.nixosModules.disko
    inputs.lanzaboote.nixosModules.lanzaboote

    ./boot.nix
    ./disko.nix
  ];

  atelier.system.core.hostName = "athena";
  atelier.hardware.graphics.vendor = "headless";
  atelier.hardware.efi.enable = true;
  atelier.system.theming.enable = true;

  atelier.kits.development.enable = true;
  atelier.kits.virtualisation.enable = true;
}
