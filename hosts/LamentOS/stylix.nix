{
  config,
  lib,
  pkgs,
  ...
}: {
  stylix = {
    enable = true;
    enableReleaseChecks = false;
    image = ./wallpaper.png;
    colorGeneration = {
      polarity = "dark";
    };

    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrains Mono Nerd Font";
      };
      sansSerif = {
        package = pkgs.fira;
        name = "Fira Sans";
      };
      serif = {
        package = pkgs.crimson;
        name = "Crimson Pro";
      };
      sizes = {
        applications = 12;
        desktop = 10;
      };
    };

    cursor = {
      package = pkgs.numix-cursor-theme;
      name = "Numix-Cursor-Light";
      size = 36;
    };

    opacity = {
      applications = 0.85;
      terminal = 0.85;
      desktop = 0.5;
      popups = 0.95;
    };
  };
}
