{inputs, ...}: {
  flake.nixosModules.nixbldRemoteUser = {
    config,
    lib,
    pkgs,
    ...
  }: {
    users.users.nixbldRemote = {
      isSystemUser = true;
      group = "nixbldRemote";
      home = "/var/lib/nixbldRemote/";
      createHome = true;
      openssh.authorizedKeys.keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH8B07n/Z9HSnUkD5w5tm26eSwSiQnaxUVRexV9B/Wvm nixbldRemote@ishtar"];
    };
    users.groups.nixbldRemote = {};
    nix.settings = {
      trusted-users = ["nixbldRemote"];
    };
  };
}
