{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
in {
  options.mods.ssh = {
    enable = mkEnableOption "Enable SSH communication";
  };

  config = mkIf config.mods.ssh.enable {

  };
}