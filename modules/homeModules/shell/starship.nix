{ ... }: {
  # starship prompt, fleet-wide. this module only wires the shell init + package
  # + STARSHIP_CONFIG env (settings = {} means HM writes NO config file). the
  # actual ~/.config/starship.toml is managed per-host, because noctalia's
  # matugen template injects the palette straight into it (starship has no
  # `include`): servers get a read-only `body + Catppuccin` from users/lament.nix,
  # ishtar seeds a writable copy that noctalia owns (see homeConfigurations/ishtar.nix).
  flake.homeModules.starship = { ... }: {
    programs.starship = {
      enable = true;
      settings = { };
    };
  };
}
