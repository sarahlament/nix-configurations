{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkOption mkIf mkEnableOption types;
  cfg = config.atelier.system.theming;
in {
  options.atelier.system.theming = {
    enable = mkEnableOption "Should we provide a default theme across the system?";
    useDefaultTheme = mkOption {
      type = types.bool;
      default = true;
      description = "Enable a default theme for the system";
    };

    fonts.monospace = mkOption {
      type = types.submodule {
        options = {
          package = mkOption {type = types.package;};
          name = mkOption {type = types.str;};
        };
      };
      default = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrains Mono Nerd Font";
      };
      description = "Monospace font couplet for the system";
    };
    fonts.sansSerif = mkOption {
      type = types.submodule {
        options = {
          package = mkOption {type = types.package;};
          name = mkOption {type = types.str;};
        };
      };
      default = {
        package = pkgs.fira;
        name = "Fira Sans";
      };
      description = "SansSerif font couplet for the system";
    };
    fonts.serif = mkOption {
      type = types.submodule {
        options = {
          package = mkOption {type = types.package;};
          name = mkOption {type = types.str;};
        };
      };
      default = {
        package = pkgs.crimson;
        name = "Crimson Pro";
      };
      description = "Serif font couplet for the system";
    };

    cursor = mkOption {
      type = types.submodule {
        options = {
          package = mkOption {type = types.package;};
          name = mkOption {type = types.str;};
          size = mkOption {type = types.int;};
        };
      };
      default = {
        package = pkgs.numix-cursor-theme;
        name = "Numix-Cursor-Light";
        size = 36;
      };
      description = "Cursor triplet for the system";
    };
  };

  config = mkIf cfg.enable {
    stylix = {
      enable = true;
      base16Scheme = mkIf (cfg.useDefaultTheme) "${pkgs.base16-schemes}/share/themes/atelier-cave.yaml";
      fonts = {
        monospace = {
          package = cfg.fonts.monospace.package;
          name = cfg.fonts.monospace.name;
        };
        sansSerif = {
          package = cfg.fonts.sansSerif.package;
          name = cfg.fonts.sansSerif.name;
        };
        serif = {
          package = cfg.fonts.serif.package;
          name = cfg.fonts.serif.name;
        };
      };

      cursor = {
        package = cfg.cursor.package;
        name = cfg.cursor.name;
        size = cfg.cursor.size;
      };
    };

    boot.plymouth.enable = true;
    boot.kernelParams = ["quiet" "splash"];
  };
}
