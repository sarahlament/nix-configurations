{
  config,
  lib,
  pkgs,
  ...
}: {
  environment.defaultPackages = [pkgs.sops pkgs.age];
  sops.age.keyFile = "/persist/key.age";
  sops.defaultSopsFile = ./secrets.yaml;
  sops.defaultSopsFormat = "yaml";
}
