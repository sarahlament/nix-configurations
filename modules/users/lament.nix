{ self, ... }: {
  flake.nixosModules.lamentUser =
    {
      config,
      lib,
      ...
    }:
    let
      inherit (lib) mkEnableOption optionals mkIf;
      inherit (self.myLib.helpers) mkSopsFile;
      cfg = config.modules.lament;
    in
    {
      options.modules.lament = {
        desktop.enable = mkEnableOption "Enable desktop config";
      };

      config = {
        sops.secrets.lamentUserPass = {
          sopsFile = mkSopsFile "pass";
          neededForUsers = true;
        };
        sops.secrets.lamentKey = {
          sopsFile = mkSopsFile "privkeys";
          owner = "lament";
          path = "/home/lament/.ssh/id_ed25519";
        };
        nix.settings.trusted-users = [ "lament" ];
        users.users.lament = {
          description = "Sarah Lament";
          hashedPasswordFile = config.sops.secrets.lamentUserPass.path;
          isNormalUser = true;
          openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBWSe/rbjk1/7meA90ZAg1hR3TcbKUgjB4GEl18SF1bZ"
          ];
          extraGroups = [
            "wheel"
            "systemd-journal"
            "plugdev"
            "video"
            "docker"
            "libvirtd"
            "gamemode"
          ];
        };
        services.displayManager.autoLogin = mkIf cfg.desktop.enable {
          enable = true;
          user = "lament";
        };

        home-manager.users.lament = {
          imports =
            with self.homeModules;
            [
              git
              jj
              kitty
            ]
            ++ optionals cfg.desktop.enable [
              vscode
              {
                programs = {
                  obsidian.enable = true;
                  firefox.enable = true;
                };
              }
            ]; # ++ optionals (cfg.server.enable)[]; if needed/wanted

          home = {
            inherit (config.system) stateVersion;
            username = "lament";
            homeDirectory = "/home/lament";
            shell.enableShellIntegration = true;
          };
        };
      };
    };
}
