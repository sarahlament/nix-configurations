{
  inputs,
  self,
  self',
  ...
}: {
  perSystem = {
    config,
    pkgs,
    ...
  }: {
    packages.lsfg-vk = pkgs.callPackage (self + "/static/packages/lsfg-vk.nix") {};
    overlayAttrs = {
      inherit (config.packages) lsfg-vk;
    };
  };
}
