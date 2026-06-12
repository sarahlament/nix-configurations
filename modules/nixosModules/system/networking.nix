{inputs, ...}: {
  flake.nixosModules.networking = {
    config,
    lib,
    pkgs,
    ...
  }: {
    networking = {
      networkmanager.enable = lib.mkDefault true;
      firewall.trustedInterfaces = ["tailscale0"];
      nftables.enable = true;
    };

    services = {
      resolved.enable = true;
      tailscale = {
        enable = true;
        useRoutingFeatures = "client";
        extraUpFlags = [
          "--login-server https://headscale.lament.gay"
        ];
      };

      borgbackup.jobs.${config.networking.hostName} = {
        paths = ["/var/lib/tailscale"];
      };
    };
  };
}
