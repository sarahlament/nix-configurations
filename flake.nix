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
      url = "path:/home/lament/renix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.inputs.systems.follows = "systems";
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
        nixpkgs.follows = "nixpkgs";
        flake-compat.follows = "flake-compat";
        git-hooks.inputs.gitignore.follows = "gitignore";
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
