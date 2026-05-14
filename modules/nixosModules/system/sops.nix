{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.sops = {
    config,
    lib,
    pkgs,
    ...
  }: {
    imports = [inputs.sops.nixosModules.sops];
    environment.defaultPackages = [pkgs.sops pkgs.age];
    sops.age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
    sops.defaultSopsFile = self + "/secrets.yaml";
    sops.defaultSopsFormat = "yaml";
  };
}
