{ inputs, self, ... }: {
  # ishtar's lament HM, applied standalone (`just home` -> home-manager switch),
  # decoupled from nixos-rebuild so editor/user tweaks don't need a system build.
  # servers keep the integrated path (users/lament.nix). nvf rides along here
  # (shared config via myLib.nvfModule) so nvim iterates without a system rebuild.
  flake.homeConfigurations."lament@ishtar" = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = import inputs.nixpkgs {
      system = "x86_64-linux";
      config.allowUnfree = true;
      overlays = [
        self.overlays.default
        self.overlays.pinned
      ];
    };
    extraSpecialArgs = { inherit inputs self; };
    modules =
      (with self.homeModules; [
        # mirrors the sharedModules list in core.nix (fleet-wide user modules)
        btop
        fastfetch
        homeShell
        hyfetch
        posh
        # lament's profile: base + desktop
        lamentHome
        lamentDesktop
      ])
      ++ [
        inputs.nvf.homeManagerModules.default
        self.myLib.nvfModule
        {
          home = {
            stateVersion = "26.05";
            sessionVariables.EDITOR = "nvim";
            # the home-manager CLI, so `home-manager switch` works from the profile
            packages = [ inputs.home-manager.packages.x86_64-linux.default ];
          };
          programs.nvf.enable = true;
        }
      ];
  };
}
