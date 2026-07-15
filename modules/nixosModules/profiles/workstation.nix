{ ... }: {
  flake.nixosModules.workstation =
    {
      config,
      lib,
      ...
    }:
    let
      inherit (lib) mkEnableOption mkIf optionals;
      cfg = config.modules.workstation;
    in
    {
      options.modules.workstation.bluetooth.enable = mkEnableOption "Enable bluetooth";
      config = {
        hardware.bluetooth.enable = mkIf cfg.bluetooth.enable true;
        # flatpak apps (/var/lib/flatpak) always persist; bluetooth pairings
        # (/var/lib/bluetooth) only when the option's on - both survive the wipe
        environment.persistence."/persist".directories = [
          "/var/lib/flatpak"
        ]
        ++ optionals cfg.bluetooth.enable [ "/var/lib/bluetooth" ];
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
