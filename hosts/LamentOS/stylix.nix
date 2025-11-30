{
  config,
  lib,
  pkgs,
  ...
}: {
  stylix = {
    enableReleaseChecks = false;
    image = ./wallpaper.png;
    colorGeneration = {
      polarity = "dark";
    };

    fonts.sizes = {
      applications = 12;
      desktop = 10;
    };

    opacity = {
      applications = 0.85;
      terminal = 0.85;
      desktop = 0.5;
      popups = 0.95;
    };
  };
}
