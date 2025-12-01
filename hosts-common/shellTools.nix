{
  config,
  lib,
  pkgs,
  ...
}: {
  home-manager.sharedModules = [
    {
      home.shellAliases = {
        cat = "bat";
        ls = "eza";
        la = "eza -a --grid";
        lt = "eza --tree --level=1";
        ll = "eza -l --grid";
        lla = "eza -la --grid";
        ltt = "eza --tree";
        grep = "rg --color=auto";
      };
      programs = {
        bat.enable = true;
        eza = {
          enable = true;
          colors = "auto";
          icons = "auto";
          extraOptions = [
            "--grid"
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
        zoxide.enable = true;
      };
    }
  ];
  security.sudo-rs.enable = true;
}
