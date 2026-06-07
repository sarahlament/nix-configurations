{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.nixconf = {
    config,
    lib,
    pkgs,
    ...
  }: {
    nixpkgs.config = {
      allowUnfree = true;
    };

    # we create our own nixbld user for remote activation
    users.groups.nixbldRemote = {};
    users.users.nixbldRemote = {
      isSystemUser = true;
      group = "nixbldRemote";
      extraGroups = ["wheel"];
      home = "/var/lib/nixbldRemote/";
      createHome = true;
      openssh.authorizedKeys.keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH8B07n/Z9HSnUkD5w5tm26eSwSiQnaxUVRexV9B/Wvm nixbldRemote@lament.gay"];
      shell = pkgs.bash;
    };

    nix = {
      settings = {
        trusted-users = ["@wheel"];
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
      };
    };
    nixpkgs.overlays = [self.overlays.default];

    programs.nh = {
      enable = true;
      flake = "/home/lament/nix-configurations";
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
