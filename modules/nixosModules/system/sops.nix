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
    sops.age.keyFile = "/persist/key.age";
    sops.defaultSopsFormat = "yaml";
  };
}
