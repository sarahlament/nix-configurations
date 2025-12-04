{
  config,
  inputs,
  ...
}: {
  imports = [
    inputs.lanzaboote.nixosModules.lanzaboote
    inputs.aagl.nixosModules.default
    inputs.stylix.nixosModules.stylix

    ./aagl.nix
    ./boot.nix
    ./develop.nix
    ./disko.nix
    ./fastfetch.nix
    ./gaming.nix
    ./kde.nix
    ./nvidia.nix
    ./packages.nix
    ./posh.nix
    ./services.nix
    ./stylix.nix
  ];
  sops.age.keyFile = "/persist/key.age";
  hardware.bluetooth.enable = true;

  networking.hostName = "ishtar";
  security.sudo-rs.wheelNeedsPassword = false;

  security.rtkit.enable = true;

  users.users.lament.extraGroups = [
    "networkmanager"
    "plugdev"
    "video"
    "docker"
    "libvirtd"
    "gamemode"
  ];
}
