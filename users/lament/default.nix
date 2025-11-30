{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) optionals;
  kits = config.atelier.kits;
in {
  sops.secrets.lamentPassHash.neededForUsers = true;
  atelier.user.lament = {
    fullName = "Sarah Lament";
    isAdmin = true;
    enableGaming = true;
    hashedPasswordFile = config.sops.secrets.lamentPassHash.path;
  };

  # yes, we declare this later. no, that does not guarantee that sshing into root works with my terminal. no, becuase that file is loaded under home-manager.users, it cannot have nixos options
  environment.systemPackages = [pkgs.kitty];

  users.users.lament.openssh.authorizedKeys.keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBWSe/rbjk1/7meA90ZAg1hR3TcbKUgjB4GEl18SF1bZ"]; # lament@LamentOS

  home-manager.users.lament = {
    imports =
      [
        inputs.nixvim.homeModules.nixvim

        ./env.nix
        ./git.nix
        ./hyfetch.nix
        ./kitty.nix
        ./nixvim.nix
        ./shell.nix
        ./system.nix
      ]
      ++ optionals kits.desktop.enable [
        ./stylix.nix
        ./vscode.nix
        ./obsidian.nix
      ];
  };
}
