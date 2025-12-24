{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) optionals;
  passFile = config.sops.secrets.lamentPassHash.path;
in {
  sops.secrets.lamentPassHash.neededForUsers = true;
  users.users.lament = {
    description = "Sarah Lament";
    hashedPasswordFile = passFile;
    isNormalUser = true;

    extraGroups = [
      "wheel"
      "systemd-journal"
    ];
  };

  users.users.lament.openssh.authorizedKeys.keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBWSe/rbjk1/7meA90ZAg1hR3TcbKUgjB4GEl18SF1bZ"]; # personal key

  home-manager.users.lament = {
    imports =
      [
        ./git.nix
        ./hyfetch.nix
        ./kitty.nix
        ./shell.nix
        ./system.nix
      ]
      ++ optionals (config.networking.hostName == "ishtar") [
        inputs.sops-nix.homeManagerModules.sops
        ./sops.nix
        ./stylix.nix
        ./vscode.nix
        {
          programs = {
            obsidian.enable = true;
            firefox.enable = true;
            zed-editor.enable = true;
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
