{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.buildMachines = {
    config,
    lib,
    pkgs,
    ...
  }: {
    sops.secrets.nixbldKey = {sopsFile = self + "/privkeys.yaml";};
    nix.distributedBuilds = true;
    nix.buildMachines = lib.mkIf (config.networking.hostName != "ishtar") [
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
