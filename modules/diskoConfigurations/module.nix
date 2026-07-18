{
  inputs,
  self,
  ...
}:
{
  flake.nixosModules.disko =
    { config, lib, ... }:
    let
      cfg = config.modules.disko;
    in
    {
      imports = [ inputs.disko.nixosModules.disko ];
      options.modules.disko.layout = lib.mkOption {
        type = lib.types.enum [
          "bios-linode"
          "uefi-plain"
          "uefi-lvm"
          "uefi-laptop"
        ];
        description = "which disk layout template this host formats with";
      };
      config.disko.devices = self.diskoConfigurations.${cfg.layout}.disko.devices;
    };
}
