{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkOption mkEnableOption types mkDefault mkIf;
  cfg = config.atelier.system.core;
in {
  options.atelier.system.core = {
    enable = mkEnableOption "Should we handle the core of the system";
    stateVersion = mkOption {
      type = types.str;
      default = "25.11";
      description = "The stateVersion we are using for the system. Unless you know what you're doing, DO NOT CHANGE THIS!";
    };
    systemType = mkOption {
      type = types.str;
      default = "x86_64-linux";
      description = "The system type we are using. You probably want to keep this as-is";
    };
    allowUnfree = mkOption {
      type = types.bool;
      default = true;
      description = "Should we allow 'unfree' software";
    };
    hostName = mkOption {
      type = types.str;
      default = "nixos";
      description = "Hostname for the system";
    };
    locale = mkOption {
      type = types.str;
      default = "en_US.UTF-8";
      example = "de_DE.UTF-8";
      description = "The locale we should use for the system";
    };
    timeZone = mkOption {
      type = types.str;
      default = "UTC";
      example = "America/Chicago";
      description = "TimeZone for the system";
    };
  };

  config = mkIf cfg.enable {
    system.stateVersion = cfg.stateVersion;

    nixpkgs.hostPlatform = cfg.systemType;
    nixpkgs.config.allowUnfree = cfg.allowUnfree;
    hardware.enableRedistributableFirmware = cfg.allowUnfree;
    networking.hostName = cfg.hostName;

    i18n.defaultLocale = cfg.locale;
    time.timeZone = cfg.timeZone;
  };
}
