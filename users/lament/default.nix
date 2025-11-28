{
  config,
  inputs,
  lib,
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

  home-manager.users.lament = {
    imports =
      [
        inputs.nixvim.homeModules.nixvim

        ./env.nix
        ./git.nix
        ./gpg.nix
        ./hyfetch.nix
        ./nixvim.nix
        ./shell.nix
        ./system.nix
      ]
      ++ optionals kits.desktop.enable [
        ./kitty.nix
        ./stylix.nix
        ./vscode.nix
        ./obsidian.nix
      ];
  };
}
