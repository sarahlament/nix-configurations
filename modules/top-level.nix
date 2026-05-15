{
  inputs,
  lib,
  pkgs,
  ...
}: {
  imports = [
    inputs.git-hooks.flakeModule
    inputs.home-manager.flakeModules.home-manager
    inputs.disko.flakeModules.disko
    inputs.flake-parts.flakeModules.easyOverlay
  ];
  systems = ["x86_64-linux"];
  perSystem = {pkgs, ...}: {
    formatter = pkgs.alejandra;
  };
}
