{
  config,
  pkgs,
  lib,
  ...
}: {
  home.shellAliases = {
    c = "clear";
    ff = "hyfetch";
    shutdown = "systemctl shutdown";
    reboot = "systemctl reboot";

    sys-rebuild = "nixos-rebuild --flake ${config.home.homeDirectory}/.nix-conf/# --sudo";
    sys-clean-gens = "nix-collect-garbage -d; sys-rebuild switch";
  };

  programs = {
    zsh = {
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
