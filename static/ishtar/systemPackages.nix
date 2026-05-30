{
  config,
  lib,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    thunderbird # email client
    waydroid # android emulator
    waydroid-helper
    libreoffice-fresh
  ];
}
