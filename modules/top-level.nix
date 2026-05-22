{
  inputs,
  lib,
  self,
  ...
}: let
  inherit (lib) mkOption types;
in {
  imports = [
    inputs.git-hooks.flakeModule
    inputs.home-manager.flakeModules.home-manager
    inputs.disko.flakeModules.disko
    inputs.flake-parts.flakeModules.easyOverlay
  ];
  
  options.flake.myLib = mkOption {
    type = types.lazyAttrsOf types.raw;
    default = {};
  };

  config = {
    systems = ["x86_64-linux"];
    perSystem = {pkgs, ...}: {
      formatter = pkgs.alejandra;
      pre-commit = {
        check.enable = true;
        settings = {
          package = pkgs.prek;
          hooks = {
            alejandra = {
              enable = true;
              package = pkgs.alejandra;
            };
            deadnix = {
              enable = true;
              package = pkgs.deadnix;
            };
          };
        };
      };
    };
  };
}
