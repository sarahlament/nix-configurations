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
              (
                { config, pkgs, ... }:
                {
                  programs = {
                    obsidian.enable = true;
                    firefox.enable = true;
                    # the generated kitty.conf just pulls in the mutable rice file
                    # (which itself includes noctalia's matugen palette).
                    kitty.extraConfig = "include /home/lament/.config/kitty/rice.conf";
                  };
                  # niri + kitty visuals live in-repo but stay mutable: symlink
                  # ~/.config straight at the work-tree so edits hot-reload with no
                  # rebuild, while jj tracks them and borg backs them up. noctalia's
                  # generated files (niri noctalia.kdl, kitty themes/) are left alone.
                  xdg.configFile = {
                    "niri/config.kdl".source =
                      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/pantheon/dotfiles/niri/config.kdl";
                    "kitty/rice.conf".source =
                      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/pantheon/dotfiles/kitty/rice.conf";
                  };
                  # cursor formerly owned by stylix (dropped with the NNN switch).
                  # explicit enable also clears the pointerCursor deprecation warning.
                  home.pointerCursor = {
                    enable = true;
                    package = pkgs.numix-cursor-theme;
                    name = "Numix-Cursor-Light";
                    size = 36;
                    gtk.enable = true;
                  };
                }
              )
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
