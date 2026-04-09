{
  config,
  lib,
  pkgs,
  ...
}: {
  programs = {
    honkers-railway-launcher.enable = true;
    sleepy-launcher.enable = true;
  };
}
