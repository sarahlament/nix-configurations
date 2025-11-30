{
  config,
  lib,
  pkgs,
  ...
}: {
  stylix = {
    enableReleaseChecks = false;
    targets.nixvim.transparentBackground = {
      main = true;
      numberLine = true;
      signColumn = true;
    };
  };
}
