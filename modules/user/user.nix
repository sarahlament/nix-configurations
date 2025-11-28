{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkOption mkEnableOption types optionals;
  inherit (lib) mkIf mkMerge mkDefault mapAttrs mapAttrsToList;
  inherit (types) str bool enum listOf nullOr path;
  cfg = config.atelier.user;
  cfgs = config.atelier.users;
  syscfg = config.atelier.system.core;
  syskits = config.atelier.kits;
in {
  options.atelier.user = mkOption {
    type = types.attrsOf (types.submodule {
      options = {
        enable = mkOption {
          type = bool;
          default = true;
          description = "Whether to create and configure this user";
        };
        fullName = mkOption {
          type = str;
          default = "System User";
          description = "Display name for the user";
        };
        shell = mkOption {
          type = enum [
            "zsh"
            "bash"
            "dash"
            "fish"
          ];
          default = "zsh";
          description = "Which shell should the user use";
        };
        isAdmin = mkOption {
          type = bool;
          default = false;
          description = "Whether this user should have admin rights";
        };
        enableDevelopment = mkEnableOption "Set the group for docker";
        enableGaming = mkEnableOption "Set the group for gamemode";
        enableVirtualisation = mkEnableOption "Set the group for virtualization";
        extraGroups = mkOption {
          type = listOf str;
          default = [];
          example = ["plugdev" "networkmanager"];
        };

        hashedPasswordFile = mkOption {
          type = nullOr path;
          default = null;
          description = "Should I use your personal hashed password instead?";
        };
      };
    });
    default = {};
    description = "User configurations for the system";
  };
  options.atelier.users.sudoNoPassword = mkEnableOption "Should sudo work without a password";

  config = {
    users.users =
      mapAttrs (
        username: userConfig:
          mkIf userConfig.enable {
            description = userConfig.fullName;
            isNormalUser = true;
            initialHashedPassword = mkIf (userConfig.hashedPasswordFile == null) (mkDefault "$6$p20S/Lmo4mac8WYC$LcJ1.Shd2nqNms10afnhD6//Nm3gn7HdHZlZwsNCx2bYFRC.iNyHU5vbRpo96FOV33JuMyxV32izMy8zW89mP1");
            hashedPasswordFile = userConfig.hashedPasswordFile;
            extraGroups =
              optionals (userConfig.isAdmin) [
                "wheel"
                "systemd-journal"
              ]
              ++ optionals (userConfig.enableDevelopment || (userConfig.isAdmin && syskits.development.enable)) ["docker"]
              ++ optionals (userConfig.enableVirtualisation || (userConfig.isAdmin && syskits.virtualisation.enable)) ["libvirtd"]
              ++ optionals (syscfg.enable && userConfig.isAdmin) ["networkmanager"]
              ++ optionals (userConfig.enableGaming) ["gamemode"]
              ++ optionals (syskits.desktop.enable) ["plugdev"]
              ++ userConfig.extraGroups;
            shell = pkgs.${userConfig.shell};
          }
      )
      cfg;

    programs = mkMerge (
      mapAttrsToList (
        username: userConfig:
          mkIf userConfig.enable {
            ${userConfig.shell}.enable = true;
          }
      )
      cfg
    );

    home-manager.users =
      mapAttrs (
        username: userConfig:
          mkIf userConfig.enable {
            home.username = username;
            home.homeDirectory = "/home/${username}";
            programs.${userConfig.shell}.enable = true;
            home.shell.enableShellIntegration = true;
            home.stateVersion = syscfg.stateVersion;
          }
      )
      cfg;

    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.backupFileExtension = "hm-backup";

    # This is in fact correct. sudoNoPasword defaults to false, which is what this needs to work correctly, so we need the inverse of the option.
    security.sudo.wheelNeedsPassword = !(cfgs.sudoNoPassword);
    security.sudo-rs.wheelNeedsPassword = !(cfgs.sudoNoPassword);
  };
}
