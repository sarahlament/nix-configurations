{
  config,
  lib,
  pkgs,
  ...
}: {
  environment.defaultPackages = [pkgs.sops pkgs.age];
  sops.age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
  sops.defaultSopsFile = ./secrets.yaml;
  sops.defaultSopsFormat = "yaml";
}
