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
        hostName = "ishtar";
        systems = ["x86_64-linux"];
        sshUser = "nixbldRemote";
        sshKey = config.sops.secrets.nixbldKey.path;
      }
    ];
  };
}
