{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.atelier.hardware.efi;
in {
  options.atelier.hardware.efi = {
    enable = mkEnableOption "Enable EFI things";
  };
  config = mkIf cfg.enable {
    boot.initrd.systemd.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.efi.efiSysMountPoint = "/efi";
  };
}
