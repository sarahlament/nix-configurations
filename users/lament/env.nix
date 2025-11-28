{
  config,
  lib,
  pkgs,
  ...
}: {
  home.sessionVariables = {
    MAKEFLAGS = "-j16"; # Parallel make jobs
  };
}
