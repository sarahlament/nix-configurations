{ self, ... }: {
  # nixpkgs-pin overlay, shared so the standalone homeConfiguration
  # (homeConfigurations/ishtar.nix) uses the same pin as the system nixpkgs.
  # numix-cursor-theme otherwise rebuilds on every nixpkgs bump.
  flake.overlays.pinned = final: _prev: {
    inherit
      (import (fetchTarball {
        url = "https://github.com/nixos/nixpkgs/archive/a799d3e3886da994fa307f817a6bc705ae538eeb.tar.gz";
        sha256 = "sha256:11mhk782xy1n58518f86k6fcvxjaaim3mk9nmhx68fg5i2jg9ayx";
      }) { system = final.stdenv.hostPlatform.system; })
      numix-cursor-theme
      ;
  };

  perSystem =
    {
      config,
      pkgs,
      ...
    }:
    {
      packages = {
        lsfg-vk = pkgs.callPackage (self + "/static/packages/lsfg-vk.nix") { };
        forgejo-themes = pkgs.callPackage (self + "/static/packages/forgejo-themes.nix") { };
        fail2ban-email = pkgs.writeShellApplication {
          name = "fail2ban-email";
          runtimeInputs = with pkgs; [
            dnsutils
            curl
            systemd
          ];
          text = builtins.readFile (self + "/static/packages/fail2ban-email.sh");
        };
      };
      overlayAttrs = {
        inherit (config.packages) lsfg-vk fail2ban-email forgejo-themes;
      };
    };
}
