{
  config,
  lib,
  pkgs,
  ...
}: {
  networking.networkmanager.enable = lib.mkDefault true;
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
    extraUpFlags = [
      "--login-server https://headscale.lament.gay"
    ];
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };
}
