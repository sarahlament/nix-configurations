{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: {
  nix.settings = {
    substituters = [
      "https://ezkea.cachix.org"
    ];
    trusted-public-keys = [
      "ezkea.cachix.org-1:ioBmUbJTZIKsHmWWXPe1FSFbeVe+afhfgqgTSNd34eI="
    ];
  };
  nixpkgs.overlays = [
    inputs.my-overlays.overlays.default
  ];
}
