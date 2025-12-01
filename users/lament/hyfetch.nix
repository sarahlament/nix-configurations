{
  config,
  lib,
  pkgs,
  ...
}: {
  programs = {
    hyfetch = {
      enable = true;
      settings = {
        preset = "transfeminine";
        mode = "rgb";
        light_dark = "dark";
        lightness = 0.65;
        color_align = {
          mode = "horizontal";
        };
        backend = "fastfetch";
        pride_month_disable = false;
      };
    };
  };
}
