{
  config,
  lib,
  pkgs,
  ...
}: {
  security.rtkit.enable = true;
  services = {
    pipewire = {
      enable = true;
      wireplumber.enable = true;
    };
  };
  programs.noisetorch.enable = true;

  environment.systemPackages = with pkgs; [
    pwvucontrol
    easyeffects
  ];
}
