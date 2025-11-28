{
  config,
  lib,
  pkgs,
  ...
}: {
  stylix = {
    targets.nixvim.transparentBackground = {
      main = true;
      numberLine = true;
      signColumn = true;
    };
  };
}
