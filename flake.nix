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

    #########################
    ## HOME MANAGER INPUTS ##
    #########################
    # nixvim is neovim and plugins done the nix way
    nixvim = {
      url = "github:nix-community/nixvim/main";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
        systems.follows = "systems";
        nuschtosSearch.inputs.flake-utils.follows = "flake-utils";
      };
    };

    ###################
    ## ATHENA INPUTS ##
    ###################
    # simple, declarative mailserver for NixOS
    nixos-mailserver = {
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-compat.follows = "flake-compat";
        git-hooks.inputs.gitignore.follows = "gitignore";
      };
    };

    #####################
    ## LAMENTOS INPUTS ##
    #####################
    # stylix provides system-level theming
    stylix = {
      # I'm going to test matugen theming once again
      #url = "github:nix-community/stylix/";
      url = "github:make-42/stylix/matugen";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
        systems.follows = "systems";
      };
    };

    # lanzaboote is a secure boot implementation, requiring your own keys
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.3";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-compat.follows = "flake-compat";
        flake-parts.follows = "flake-parts";
        pre-commit-hooks-nix.inputs.gitignore.follows = "gitignore";
        rust-overlay.follows = "rust-overlay";
      };
    };

    # anime games launcher
    aagl = {
      url = "github:ezKEa/aagl-gtk-on-nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-compat.follows = "flake-compat";
        rust-overlay.follows = "rust-overlay";
      };
    };

    # this allows us to have up-to-date claude-code instead of the late updates provided by nixpkgs
    # note: this is an overlay, not a module
    claude-code = {
      url = "github:sadjow/claude-code-nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };

    ###################
    ## DEDUPLICATION ##
    ###################
    # these are declared to deduplicate sources within my flake.lock
    systems.url = "github:nix-systems/default";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
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
  };
  outputs = inputs @ {nixpkgs, ...}: {
    # this is my personal system config
    nixosConfigurations.ishtar = nixpkgs.lib.nixosSystem {
      specialArgs = {inherit inputs;};
      modules = [
        ./hosts-common
        ./hosts/ishtar
      ];
    };

    nixosConfigurations.athena = nixpkgs.lib.nixosSystem {
      specialArgs = {inherit inputs;};
      modules = [
        ./hosts-common
        ./hosts/athena
      ];
    };

    # I prefer how alejandra looks opposed to nixfmt
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;
  };
}
