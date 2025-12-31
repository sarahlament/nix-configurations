{
  description = "LamentOS";
  inputs = {
    ###################
    ## SHARED INPUTS ##
    ###################
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # home manager manages user-level configuration (dotfiles, packages, services)
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # disko let's me declaratively define how my disks are formatted and such
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # sops-nix is an advanced tool to store encrypted secrets along with my configuration safely
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # renix is my own host manager for NixOS
    renix = {
      url = "github:sarahlament/renix";
      inputs = {
        crane.follows = "crane";
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
        pre-commit-hooks.inputs.flake-compat.follows = "flake-compat";
        pre-commit-hooks.inputs.gitignore.follows = "gitignore";
      };
    };

    my-overlays = {
      url = "git+file:///home/lament/nix-overlays";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    #########################
    ## HOME MANAGER INPUTS ##
    #########################
    # nixvim is being replaced by NVF {soon:tm:}

    ###################
    ## ATHENA INPUTS ##
    ###################
    # simple, declarative mailserver for NixOS
    nixos-mailserver = {
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver";
      inputs = {
        flake-compat.follows = "flake-compat";
        git-hooks.inputs.gitignore.follows = "gitignore";
        nixpkgs.follows = "nixpkgs";
      };
    };

    ###################
    ## ISHTAR INPUTS ##
    ###################
    # stylix provides system-level theming
    stylix = {
      # I'm going to test matugen theming once again
      #url = "github:nix-community/stylix/";
      url = "github:nix-community/stylix/?ref=pull/892/head";
      inputs = {
        flake-parts.follows = "flake-parts";
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
      };
    };

    # lanzaboote is a secure boot implementation, requiring your own keys
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.3";
      inputs = {
        crane.follows = "crane";
        flake-compat.follows = "flake-compat";
        flake-parts.follows = "flake-parts";
        nixpkgs.follows = "nixpkgs";
        pre-commit-hooks-nix.inputs.gitignore.follows = "gitignore";
        rust-overlay.follows = "rust-overlay";
      };
    };

    # anime games launcher
    aagl = {
      url = "github:ezKEa/aagl-gtk-on-nix";
      inputs = {
        flake-compat.follows = "flake-compat";
        nixpkgs.follows = "nixpkgs";
        rust-overlay.follows = "rust-overlay";
      };
    };

    # let's give antigravity a try
    antigrav = {
      url = "github:jacopone/antigravity-nix";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ###################
    ## DEDUPLICATION ##
    ###################
    # these are declared to deduplicate sources within my flake.lock
    crane = {
      url = "github:ipetkov/crane";
    };
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
    gitignore = {
      url = "github:hercules-ci/gitignore.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    systems.url = "github:nix-systems/default";
  };
  outputs = inputs @ {nixpkgs, ...}: let
    mkSystem = hostName:
      nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs;};
        modules = [
          ./hosts-common
          ./hosts/${hostName}
        ];
      };
  in {
    # this is my personal system config
    nixosConfigurations.ishtar = mkSystem "ishtar";
    nixosConfigurations.athena = mkSystem "athena";

    # I prefer how alejandra looks opposed to nixfmt
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;
  };
}
