{inputs, ...}: {
  flake.homeModules.shell = {
    config,
    lib,
    pkgs,
    ...
  }: {
    programs = {
      bat.enable = true;
      eza = {
        enable = true;
        colors = "auto";
        icons = "auto";
        extraOptions = [
          "--group-directories-first"
          "--follow-symlinks"
          "--no-filesize"
          "--no-time"
          "--no-permissions"
          "--octal-permissions"
        ];
      };
      fd.enable = true;
      fzf.enable = true;
      ripgrep.enable = true;
    };
  };
}
