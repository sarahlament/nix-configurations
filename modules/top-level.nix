{
  inputs,
  lib,
  ...
}:
let
  inherit (lib) mkOption types;
in
{
  imports = [
    inputs.git-hooks.flakeModule
    inputs.disko.flakeModules.disko
    inputs.flake-parts.flakeModules.easyOverlay
    inputs.home-manager.flakeModules.home-manager
  ];

  options.flake.myLib = mkOption {
    type = types.lazyAttrsOf types.raw;
    default = { };
  };

  config = {
    systems = [ "x86_64-linux" ];
    perSystem =
      {
        config,
        pkgs,
        ...
      }:
      {
        formatter = pkgs.nixfmt-tree;
        pre-commit = {
          settings = {
            package = pkgs.prek;
            hooks = {
              deadnix.enable = true;
              nixfmt.enable = true;
              statix.enable = true;
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
            deploy-rs
            dnsutils
            delve
            forgejo-cli
            jq
            jujutsu
            just
            nixos-anywhere
            prek
            sops
          ];
        };
      };
  };
}
