{
  config,
  lib,
  pkgs,
  ...
}: {
  home-manager.users.lament = {
    programs = {
      obsidian.enable = true;
      firefox.enable = true;
    };
  };
}
