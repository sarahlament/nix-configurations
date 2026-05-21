{
  inputs,
  self,
  ...
}: let
  activeModules = with self.nixosModules; [
    boot
    disko
    lanzaboote
    nvidia

    badDecisionSecurity
    networking
    nixconf
    pipewire
    sysShell
    sops
    ssh
    stylix

    develop
    gaming
    kde
    workstation

    rootUser
    lamentUser
  ];
in {
  flake.nixosConfigurations.ishtar = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = {inherit inputs self;};
    modules =
      activeModules
      ++ [
        (inputs.import-tree (self + "/static/ishtar"))

        {
          networking.hostName = "ishtar";
          system.stateVersion = "26.05";
          nixpkgs.hostPlatform = "x86_64-linux";

          modules.boot.desktop.enable = true;
          modules.boot.zswap.enable = true;
          modules.lament.desktop.enable = true;

          nixpkgs.overlays = [self.overlays.default];
        }
      ];
  };
}
