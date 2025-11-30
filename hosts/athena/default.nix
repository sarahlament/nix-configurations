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
    ./networking.nix

    ./services
  ];
  sops.age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];

  atelier.system.core.enable = true;
  atelier.system.core.hostName = "athena";
  atelier.hardware.graphics.vendor = "headless";

  users.users.root = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBWSe/rbjk1/7meA90ZAg1hR3TcbKUgjB4GEl18SF1bZ"
    ];
  };

  environment.systemPackages = with pkgs; [
    inetutils
    mtr
    sysstat
    htop
    tmux
    screen
  ];
}
