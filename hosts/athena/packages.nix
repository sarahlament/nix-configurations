{
  config,
  lib,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    traceroute
    mtr
    sysstat
    htop
    screen
    kexec-tools
  ];
}
