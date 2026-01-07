{
  config,
  lib,
  pkgs,
  ...
}: {
  sops.age.keyFile = "/home/lament/.config/sops/age/keys.txt";
  sops.defaultSopsFile = ../../hosts/common/secrets.yaml;
  sops.defaultSopsFormat = "yaml";

  sops.secrets.context7ApiKey = {};
  sops.templates.context7Env.content = ''
    CONTEXT7_API_KEY=${config.sops.placeholder.context7ApiKey}
  '';
  programs.zsh.envExtra = "source ${config.sops.templates.context7Env.path}";
}
