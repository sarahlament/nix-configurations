{ ... }: {
  # fleet-wide essentials only: package, terminfo, zsh integration. the visual
  # config is host-specific and lives raw + mutable on ishtar (see users/lament.nix
  # desktop block -> dotfiles/kitty/rice.conf), so it can be riced without a rebuild.
  flake.homeModules.kitty = { ... }: {
    programs.kitty = {
      enable = true;
      shellIntegration.enableZshIntegration = true;
    };
  };
}
