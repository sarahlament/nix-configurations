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
    wallpaperSrc = self + "/static/${config.networking.hostName}/wallpaper.png";
    inherit (lib) mkEnableOption mkIf;
    cfg = config.modules.stylix;
  in {
    imports = [inputs.stylix.nixosModules.stylix];
    options.modules.stylix.wallpaper = mkEnableOption "Do we have a wallpaper for this host";
    config = {
      stylix = {
        enable = true;
        enableReleaseChecks = false;
        image = mkIf cfg.wallpaper wallpaperSrc;
        polarity = "dark";

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
  };
}
