{
  config,
  lib,
  pkgs,
  ...
}: {
  sops.age.keyFile = "/home/lament/.config/sops/age/keys.txt";
  sops.defaultSopsFile = ../../hosts/common/secrets.yaml;
  sops.defaultSopsFormat = "yaml";
}
