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
        sops.secrets.lamentKey = mkIf cfg.desktop.enable {
          sopsFile = mkSopsFile "privkeys/ishtar";
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
        # autologin is handled by greetd's initial_session in profiles/niri.nix
        # now (greetd doesn't read services.displayManager.autoLogin).

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
                  # kitty pulls noctalia's matugen palette (stylix target off below)
                  kitty.extraConfig = "include /home/lament/.config/kitty/themes/noctalia.conf";
                };
                # noctalia (matugen) owns these now, not stylix. gated to the desktop
                # host so stylix-less servers never see these options.
                # (niri config is also kept RAW in ~/.config/niri; the stylix niri
                # target would otherwise clobber it with a bindless config.kdl.)
                stylix.targets = {
                  niri.enable = false;
                  kitty.enable = false;
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
