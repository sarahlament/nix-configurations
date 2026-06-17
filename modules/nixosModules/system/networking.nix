{inputs, ...}: {
  flake.nixosModules.networking = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) mkDefault;
  in {
    networking = {
      networkmanager.enable = lib.mkDefault true;
      firewall.trustedInterfaces = ["tailscale0"];
      nftables.enable = true;
    };

    services = {
      resolved.enable = mkDefault true;
      tailscale = {
        enable = true;
        useRoutingFeatures = "client";
        extraUpFlags = [
          "--login-server https://hs.lament.gay:8443"
        ];
      };

      borgbackup.jobs.${config.networking.hostName} = {
        paths = ["/var/lib/tailscale"];
      };
    };
  };
}
