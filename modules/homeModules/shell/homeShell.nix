{inputs, ...}: {
  flake.homeModules.homeShell = {
    config,
    lib,
    pkgs,
    ...
  }: {
    home = {
      sessionVariables = {
        MAKEFLAGS = "-j16"; # Parallel make jobs
      };
      shellAliases = {
        c = "clear";
        ff = "hyfetch";
        shutdown = "systemctl poweroff";
        reboot = "systemctl reboot";

        cat = "bat";
        ls = "eza";
        la = "eza -a";
        lt = "eza --tree --level=1";
        ll = "eza -l";
        lla = "eza -la";
        ltt = "eza --tree";
        grep = "rg --color=auto";
        kssh = "kitten ssh";
      };
    };

    programs = {
      zsh = {
        enable = true;
        enableCompletion = true;
        autosuggestion.enable = true;
        autosuggestion.strategy = [
          "history"
          "completion"
        ];
        history.append = true;
        syntaxHighlighting.enable = true;

        setOptions = ["NO_AUTOPUSHD"];

        oh-my-zsh = {
          enable = true;

          plugins = [
            "sudo"
            "fancy-ctrl-z"
            "gitfast"
            "per-directory-history"
          ];
        };
      };

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
      zoxide = {
        enable = true;
        enableZshIntegration = true;
      };

      claude-code.enable = true;
    };
  };
}
