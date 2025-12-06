{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://ezkea.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "ezkea.cachix.org-1:ioBmUbJTZIKsHmWWXPe1FSFbeVe+afhfgqgTSNd34eI="
      ];
      trusted-users = ["lament"];
    };

    nixPath = ["nixpkgs=${inputs.nixpkgs}"];
  };

  nixpkgs.overlays = [
    (import ../packages)
    (final: prev:
      lib.recursiveUpdate prev {
        vscode-extensions.anthropic.claude-code = prev.vscode-extensions.anthropic.claude-code.overrideAttrs (old: {
          src = old.src.overrideAttrs (oldSrc: {
            outputHash = "sha256-j5yeFtbaW0UVrchKOcqBO60ay9PuPDS4jQzz+GN+56U=";
          });
        });
      })
  ];
}
