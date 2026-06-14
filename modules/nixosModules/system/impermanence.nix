{inputs, ...}: {
  flake.nixosModules.impermanence = {
    config,
    lib,
    pkgs,
    ...
  }: {
    fileSystems."/persist".neededForBoot = true;
  };
}
