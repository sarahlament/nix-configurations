{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) optionals;
in {
  sops.secrets.lamentPassHash.neededForUsers = true;
  users.users.lament = {
    description = "Sarah Lament";
    hashedPasswordFile = config.sops.secrets.lamentPassHash.path;
    isNormalUser = true;

    extraGroups = [
      "wheel"
      "systemd-journal"
    ];
  };

  users.users.lament.openssh.authorizedKeys.keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBWSe/rbjk1/7meA90ZAg1hR3TcbKUgjB4GEl18SF1bZ"]; # lament@LamentOS

  home-manager.users.lament = {
    imports =
      [
    inputs.nixvim.homeModules.nixvim
        ./git.nix
        ./hyfetch.nix
        ./kitty.nix
        ./nixvim.nix
        ./shell.nix
        ./system.nix
      ]
      ++ optionals (config.networking.hostName == "ishtar") [
        ./stylix.nix
        ./vscode.nix
        {
          programs = {
            obsidian.enable = true;
            firefox.enable = true;
          };
        }
      ];
    home = {
      stateVersion = config.system.stateVersion;
      username = "lament";
      homeDirectory = "/home/lament";
      shell.enableShellIntegration = true;
    };
  };
}
