{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.stylix = {
    config,
    lib,
    pkgs,
    ...
  }: let
    wallpaper = self + "/static/${config.networking.hostName}/wallpaper.png";
  in {
    imports = [inputs.stylix.nixosModules.stylix];
    stylix = {
      enable = true;
      enableReleaseChecks = false;
      image = wallpaper;
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

    boot = {
      plymouth.enable = true;
      kernelParams = ["splash"];
    };
  };
}
