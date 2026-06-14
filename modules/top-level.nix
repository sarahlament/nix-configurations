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
    inputs.disko.flakeModules.disko
    inputs.flake-parts.flakeModules.easyOverlay
    inputs.home-manager.flakeModules.home-manager
  ];

  options.flake.myLib = mkOption {
    type = types.lazyAttrsOf types.raw;
    default = {};
  };

  config = {
    systems = ["x86_64-linux"];
    perSystem = {
      config,
      pkgs,
      ...
    }: {
      formatter = pkgs.alejandra;
      pre-commit = {
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
              settings = {
                noLambdaPatternNames = true;
                noLambdaArg = true;
              };
            };
          };
        };
      };
      devShells.default = pkgs.mkShell {
        shellHook = ''
          ${config.pre-commit.installationScript}
          export FLAKE=$(pwd)
          alias j='just'
        '';
        packages = with pkgs; [
          age
          jq
          just
          sops
        ];
      };
    };
  };
}
