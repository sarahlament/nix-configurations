{
  inputs = {
    ###################
    ## SHARED INPUTS ##
    ###################
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-small.url = "github:nixos/nixpkgs/nixos-unstable-small";
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:denful/import-tree";

    # home manager manages user-level configuration (dotfiles, packages, services)
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # disko lets me declaratively define how my disks are formatted and such
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # sops-nix is an advanced tool to store encrypted secrets along with my configuration safely
    sops = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    #########################
    ## HOME MANAGER INPUTS ##
    #########################
    nvf = {
      url = "github:notashelf/nvf";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-compat.follows = "flake-compat";
        flake-parts.follows = "flake-parts";
        systems.follows = "systems";
      };
    };

    ###################
    ## ATHENA INPUTS ##
    ###################
    # simple, declarative mailserver for NixOS
    nixos-mailserver = {
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver";
      inputs = {
        flake-compat.follows = "flake-compat";
        git-hooks.inputs.gitignore.follows = "gitignore";
        nixpkgs.follows = "nixpkgs-small";
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

    ###################
    ## DEDUPLICATION ##
    ###################
    # these are declared to deduplicate sources within my flake.lock
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs = {
        flake-compat.follows = "flake-compat";
        gitignore.follows = "gitignore";
        nixpkgs.follows = "nixpkgs";
      };
    };
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
    systems.url = "github:nix-systems/default";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;}
    (inputs.import-tree ./modules);
}
