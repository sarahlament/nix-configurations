{
  config,
  inputs,
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    inputs.disko.nixosModules.disko
    inputs.nixos-mailserver.nixosModules.mailserver

    ./boot.nix
    ./disko.nix
    ./fastfetch.nix
    ./network.nix
    ./packages.nix

    ./services
  ];
  sops.age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
  networking.hostName = "athena";
}
