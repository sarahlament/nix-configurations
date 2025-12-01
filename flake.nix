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
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ###################
    ## ATHENA INPUTS ##
    ###################
    # simple, declarative mailserver for NixOS
    nixos-mailserver = {
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    #####################
    ## LAMENTOS INPUTS ##
    #####################
    # stylix provides system-level theming
    stylix = {
      # I'm going to test matugen theming once again
      #url = "github:nix-community/stylix/";
      url = "github:make-42/stylix/matugen";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # lanzaboote is a secure boot implementation, requiring your own keys
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.3";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # anime games launcher
    aagl = {
      url = "github:ezKEa/aagl-gtk-on-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # this allows us to have up-to-date claude-code instead of the late updates provided by nixpkgs
    # note: this is an overlay, not a module
    claude-code = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = inputs @ {
    nixpkgs,
    self,
    ...
  }: {
    # here we 'expose' our modules, so they can be used without my personal system configs
    nixosModules = {
      default = self.nixosModules.atelier;
      atelier = import ./modules/kits inputs;
    };

    # this is my personal system config
    nixosConfigurations.LamentOS = nixpkgs.lib.nixosSystem {
      specialArgs = {inherit inputs;};
      modules = [
        self.nixosModules.atelier
        ./hosts-common
        ./hosts/LamentOS
        ./users/lament
      ];
    };

    nixosConfigurations.athena = nixpkgs.lib.nixosSystem {
      specialArgs = {inherit inputs;};
      modules = [
        self.nixosModules.atelier
        ./hosts-common
        ./hosts/athena
        ./users/lament
      ];
    };

    # I prefer how alejandra looks opposed to nixfmt
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;
  };
}
