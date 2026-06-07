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
    sops.age.keyFile = "/persist/key.age";
    sops.defaultSopsFile = self + "/secrets.yaml";
    sops.defaultSopsFormat = "yaml";
  };
}
