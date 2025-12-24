{
  config,
  lib,
  pkgs,
  ...
}: {
  sops.age.keyFile = "/home/lament/.config/sops/age/keys.txt";
  sops.defaultSopsFile = ../../hosts-common/secrets.yaml;
  sops.defaultSopsFormat = "yaml";

  sops.secrets.context7-api-key = {};
  programs.zsh.envExtra = "export CONTEXT7_API_KEY=$(cat ${config.sops.secrets.context7-api-key.path})";
}
