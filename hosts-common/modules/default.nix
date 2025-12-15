{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./gaming.nix
    ./kde.nix
  ];
}
