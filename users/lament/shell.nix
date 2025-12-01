{
  config,
  pkgs,
  lib,
  ...
}: {
  home = {
    sessionVariables = {
      MAKEFLAGS = "-j16"; # Parallel make jobs
    };
    shellAliases = {
      c = "clear";
      ff = "hyfetch";
      shutdown = "systemctl shutdown";
      reboot = "systemctl reboot";

      sys-rebuild = "nixos-rebuild --flake ${config.home.homeDirectory}/.nix-conf/# --sudo";
      athena-rebuild = "nixos-rebuild --flake ${config.home.homeDirectory}/.nix-conf/# --ask-sudo-password --target athena.ts.lament.gay";
      sys-clean-gens = "nix-collect-garbage -d; sys-rebuild switch";
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
  };
}
