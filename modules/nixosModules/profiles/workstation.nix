{ ... }: {
  flake.nixosModules.workstation =
    {
      config,
      lib,
      ...
    }:
    let
      inherit (lib) mkEnableOption mkIf;
      cfg = config.modules.workstation;
    in
    {
      options.modules.workstation.bluetooth.enable = mkEnableOption "Enable bluetooth";
      config = {
        hardware.bluetooth.enable = mkIf cfg.bluetooth.enable true;
        # pairings live in /var/lib/bluetooth - survive the tmpfs-root wipe
        environment.persistence."/persist".directories = mkIf cfg.bluetooth.enable [
          "/var/lib/bluetooth"
        ];
        services = {
          flatpak.enable = true;
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
