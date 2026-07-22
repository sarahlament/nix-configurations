{ self, ... }: {
  flake.homeModules = {
    # base HM profile for lament, reusable across the integrated path (servers,
    # via lamentUser below) and ishtar's standalone homeConfiguration.
    # stateVersion is set by each consumer (integrated derives it from the
    # system; standalone pins).
    lamentHome = { ... }: {
      imports = with self.homeModules; [
        git
        jj
        kitty
      ];
      home = {
        username = "lament";
        homeDirectory = "/home/lament";
        shell.enableShellIntegration = true;
      };
    };

    # desktop apps + mutable dotfiles + cursor. only ishtar (standalone) imports this.
    lamentDesktop =
      { config, pkgs, ... }:
      {
        imports = with self.homeModules; [ vscode ];

        programs = {
          obsidian.enable = true;
          firefox.enable = true;
          # the generated kitty.conf just pulls in the mutable rice file
          # (which itself includes noctalia's matugen palette).
          kitty.extraConfig = "include /home/lament/.config/kitty/rice.conf";
        };

        # niri + kitty visuals live in-repo but stay mutable: symlink ~/.config
        # straight at the work-tree so edits hot-reload with no rebuild, while jj
        # tracks them and borg backs them up. noctalia's generated files (niri
        # noctalia.kdl, kitty themes/) are left alone.
        xdg.configFile = {
          "niri/config.kdl".source =
            config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/pantheon/dotfiles/niri/config.kdl";
          "kitty/rice.conf".source =
            config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/pantheon/dotfiles/kitty/rice.conf";
        };

        home = {
          # swayidle drives the niri DPMS timer (spawned from config.kdl):
          # monitors off after 5 min idle, back on with input.
          packages = [ pkgs.swayidle ];

          # cursor formerly owned by stylix (dropped with the NNN switch).
          # explicit enable also clears the pointerCursor deprecation warning.
          pointerCursor = {
            enable = true;
            package = pkgs.numix-cursor-theme;
            name = "Numix-Cursor-Light";
            size = 36;
            gtk.enable = true;
          };
        };
      };
  };

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
        standalone = mkEnableOption "lament HM is applied standalone, not via this NixOS module";
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

        # integrated HM: servers (and any future desktop host that stays
        # integrated). ishtar sets standalone = true and gets its HM from
        # homeConfigurations/ishtar.nix instead, so it's excluded here.
        home-manager.users.lament = mkIf (!cfg.standalone) {
          imports = [
            self.homeModules.lamentHome
          ]
          ++ optionals cfg.desktop.enable [ self.homeModules.lamentDesktop ];
          home.stateVersion = config.system.stateVersion;

          # servers have no matugen, so resolve `palette = "noctalia"` with a fixed
          # Catppuccin block appended to the shared prompt body. ishtar instead
          # seeds a writable copy noctalia injects (homeConfigurations/ishtar.nix).
          xdg.configFile."starship.toml".text =
            builtins.readFile ../../dotfiles/starship/starship.toml
            + builtins.readFile ../../dotfiles/starship/palette-catppuccin.toml;
        };
      };
    };
}
