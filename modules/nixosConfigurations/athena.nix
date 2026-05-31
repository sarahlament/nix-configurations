{
  inputs,
  self,
  ...
}: let
  activeModules = with self.nixosModules; [
    boot
    disko
    linodeBase

    buildMachines
    networking
    nixconf
    sysShell
    sops

    caddy
    forgejo
    forgejo-runner
    gollum
    headscale
    mailserver
    monitoring
    vaultwarden

    rootUser
    lamentUser
  ];
in {
  flake.nixosConfigurations.athena = inputs.nixpkgs-small.lib.nixosSystem {
    specialArgs = {inherit inputs self;};
    modules =
      activeModules
      ++ [
        (inputs.import-tree (self + "/static/athena"))

        {
          networking.hostName = "athena";
          system.stateVersion = "26.05";
          nixpkgs.hostPlatform = "x86_64-linux";

          modules.boot.zram.enable = true;
          modules.networking.ssh.public = true;
        }
      ];
  };
}
