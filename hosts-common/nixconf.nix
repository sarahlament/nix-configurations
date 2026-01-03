{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  programs.nix-ld.enable = true;
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
      trusted-users = ["lament"];
    };
  };

  programs.nh = {
    enable = true;
    flake = "/home/lament/nix-configurations";
    clean = {
      enable = true;
      extraArgs = "--keep 3 --optimise";
      dates = "weekly";
    };
  };

  nixpkgs.overlays = [
    inputs.my-overlays.overlays.default

    (final: prev: {
      luajitPackages = prev.luajitPackages.overrideScope (lfinal: lprev: {
        luaossl = lprev.luaossl.overrideAttrs (old: {
          # GCC 14 makes this an error; downgrade it to a warning so it builds.
          env =
            (old.env or {})
            // {
              NIX_CFLAGS_COMPILE = (old.env.NIX_CFLAGS_COMPILE or "") + " -Wno-error=incompatible-pointer-types";
            };
        });
      });
    })
  ];
}
