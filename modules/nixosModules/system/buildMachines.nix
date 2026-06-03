{inputs, ...}: {
  flake.nixosModules.buildMachines = {
    config,
    lib,
    pkgs,
    ...
  }: {
    sops.secrets.nixbldKey = {};
    nix.distributedBuilds = true;
    nix.buildMachines = [
      {
        hostName = "ishtar.ts";
        systems = ["x86_64-linux"];
        protocol = "ssh-ng";
        sshUser = "nixbldRemote";
        sshKey = config.sops.secrets.nixbldKey.path;
      }
    ];
  };
}
