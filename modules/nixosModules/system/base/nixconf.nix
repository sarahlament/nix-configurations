{ self, ... }: {
  flake.nixosModules.nixconf = { pkgs, ... }: {
    nixpkgs.config = {
      allowUnfree = true;
    };

    # deployer: fleet-wide SSH target for deploy-rs activation (wheel + passwordless sudo)
    users.groups.deployer = { };
    users.users.deployer = {
      isSystemUser = true;
      group = "deployer";
      extraGroups = [ "wheel" ];
      home = "/var/lib/deployer/";
      createHome = true;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHo4ATn65VJkkEBvL/WQ6dnrT+v9F2effgIrQwcYCiR5 deployer@pantheon"
      ];
      shell = pkgs.bash;
    };

    nix = {
      settings = {
        trusted-users = [ "@wheel" ];
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        substituters = [
          "https://cache.nixos.org"
          "https://nix-community.cachix.org"
          "https://cuda-maintainers.cachix.org"
          "https://niri.cachix.org"
          "https://noctalia.cachix.org"
        ];
        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
          "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
          "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
        ];
      };
    };
    nixpkgs.overlays = [
      self.overlays.default
      self.overlays.pinned # numix-cursor-theme pin (shared with the standalone HM)
    ];

    programs.nh = {
      enable = true;
      flake = "/home/lament/Projects/pantheon";
      clean = {
        enable = true;
        extraArgs = "--keep 3 --optimise";
        dates = "weekly";
      };
    };

    environment.systemPackages = with pkgs; [
      nom
      nvd
    ];
  };
}
