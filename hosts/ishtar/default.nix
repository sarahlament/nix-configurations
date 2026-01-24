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
    ./audio.nix
    ./boot.nix
    ./develop.nix
    ./disko.nix
    ./fastfetch.nix
    ./network.nix
    ./nixconf.nix
    ./nvidia.nix
    ./packages.nix
    ./posh.nix
    ./services.nix
    ./stylix.nix
  ];
  kde.enable = true;
  gaming.enable = true;

  sops.age.keyFile = "/persist/key.age";
  hardware.bluetooth.enable = true;

  networking.hostName = "ishtar";

  users.users.lament.extraGroups = [
    "networkmanager"
    "plugdev"
    "video"
    "docker"
    "libvirtd"
    "gamemode"
  ];
}
