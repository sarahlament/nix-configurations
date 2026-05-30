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
    assertions = [
      {
        assertion = config.sops.age.sshKeyPaths != [] || config.sops.age.keyFile != null;
        message = "sops can't decrypt anything! provide an ssh host key or the device's age key.";
      }
    ];
  };
}
