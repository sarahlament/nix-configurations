{
  config,
  lib,
  pkgs,
  ...
}: {
  environment.defaultPackages = [pkgs.sops pkgs.age];
  sops.defaultSopsFile = ./secrets.yaml;
  sops.defaultSopsFormat = "yaml";
}
