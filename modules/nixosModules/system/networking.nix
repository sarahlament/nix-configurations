{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.networking = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) mkEnableOption;
    cfg = config.modules.networking.ssh;
  in {
    options.modules.networking.ssh.public = mkEnableOption "public-facing config";
    config = {
      services.openssh = {
        enable = true;
        openFirewall = cfg.public;
        settings = {
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
          PermitRootLogin = "no";
        };
      };
      networking = {
        networkmanager.enable = lib.mkDefault true;
        firewall.trustedInterfaces = ["tailnet0"];
        nftables.enable = true;
      };

      services.tailscale = {
        enable = true;
        useRoutingFeatures = "client";
        extraUpFlags = [
          "--login-server https://headscale.lament.gay"
        ];
      };
      warnings = lib.optional (cfg.public && !config.services.fail2ban.enable) "SSH is public without fail2ban enabled...";
    };
  };
}
