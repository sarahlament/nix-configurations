{
  config,
  lib,
  pkgs,
  ...
}: {
  services = {
    flatpak.enable = true;
    fwupd.enable = true;
    tuned = {
      enable = true;
      ppdSettings.main = {
        default = "performance"; # Maps to "throughput-performance"
        battery_detection = false;
      };
    };
    displayManager.autoLogin = {
      enable = true;
      user = "lament";
    };
  };
}
