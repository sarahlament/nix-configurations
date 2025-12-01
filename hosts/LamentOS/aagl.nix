{
  config,
  lib,
  pkgs,
  ...
}: {
  programs = {
    honkers-railway-launcher.enable = true;
    sleepy-launcher.enable = true;
    anime-game-launcher.enable = true;
    wavey-launcher.enable = true;
  };
}
