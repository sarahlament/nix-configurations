{inputs, ...}: {
  flake.nixosModules.networking = {
    config,
    lib,
    pkgs,
    ...
  }: {
    networking.networkmanager.enable = lib.mkDefault true;
    networking.firewall.trustedInterfaces = ["tailnet0"];
    services.tailscale = {
      enable = true;
      useRoutingFeatures = "client";
      extraUpFlags = [
        "--login-server https://headscale.lament.gay"
      ];
    };
  };
}
