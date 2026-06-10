{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.lamentUser = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) mkEnableOption optionals;
    cfg = config.modules.lament;
  in {
    options.modules.lament = {
      desktop.enable = mkEnableOption "Enable desktop config";
    };

    config = {
      sops.secrets.lamentUserPass.neededForUsers = true;
      nix.settings.trusted-users = ["lament"];
      users.users.lament = {
        description = "Sarah Lament";
        hashedPasswordFile = config.sops.secrets.lamentUserPass.path;
        isNormalUser = true;
        openssh.authorizedKeys.keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBWSe/rbjk1/7meA90ZAg1hR3TcbKUgjB4GEl18SF1bZ"]; # personal key
        extraGroups = [
          "wheel"
          "systemd-journal"
          "networkmanager"
          "plugdev"
          "video"
          "docker"
          "libvirtd"
          "gamemode"
        ];
      };
      services.displayManager.autoLogin = {
        enable = true;
        user = "lament";
      };

      home-manager.users.lament = {
        imports = with self.homeModules;
          [
            git
            kitty
          ]
          ++ optionals (cfg.desktop.enable) [
            vscode
            {
              programs = {
                obsidian.enable = true;
                firefox.enable = true;
              };
            }
          ]; # ++ optionals (cfg.server.enable)[]; if needed/wanted

        home = {
          stateVersion = config.system.stateVersion;
          username = "lament";
          homeDirectory = "/home/lament";
          shell.enableShellIntegration = true;
        };
      };
    };
  };
}
