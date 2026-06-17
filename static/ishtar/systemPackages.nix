{
  config,
  lib,
  pkgs,
  ...
}: {
  services.fwupd.enable = false;
  environment.systemPackages = with pkgs; [
    thunderbird # email client
    waydroid # android emulator
    waydroid-helper
    libreoffice-fresh
  ];
}
