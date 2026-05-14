{inputs, ...}: {
  flake.nixosModules.workstation = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) mkEnableOption mkIf;
    cfg = config.modules.workstation;
  in {
    options.modules.workstation.bluetooth.enable = mkEnableOption "Enable bluetooth";
    config = {
      hardware.bluetooth.enable = mkIf cfg.bluetooth.enable true;
      services = {
        flatpak.enable = true;
        fwupd.enable = true;
        tuned = {
          enable = true;
          ppdSettings.main = {
            default = "performance";
            battery_detection = false;
          };
        };
      };
    };
  };
}
