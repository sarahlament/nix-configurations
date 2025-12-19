{
  config,
  lib,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    htop
    kexec-tools
    mtr
    screen
    sysstat
    traceroute
  ];
}
