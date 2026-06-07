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
    inherit (lib) mkEnableOption mapAttrs;
    inherit (self.myLib) directory;
    cfg = config.modules.networking.ssh;
  in {
    options.modules.networking.ssh.public = mkEnableOption "public-facing config";
    config = {
      sops.secrets."${config.networking.hostName}PrivKey" = {
        sopsFile = self + "/privkeys.yaml";
        reloadUnits = ["sshd.service"];
      };
      services.openssh = {
        enable = true;
        openFirewall = cfg.public;
        generateHostKeys = false; # I do this personally
        settings = {
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
          PermitRootLogin = "no";
        };
        hostKeys = [
          {
            type = "ed25519";
            path = config.sops.secrets."${config.networking.hostName}PrivKey".path;
          }
        ];
        knownHosts =
          mapAttrs (name: host: {
            hostNames = [name "${name}.ts" host.tailip];
            publicKey = host.publicKey;
          })
          directory;
      };
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
      };
      warnings = lib.optional (cfg.public && !config.services.fail2ban.enable) "SSH is public without fail2ban enabled...";
    };
  };
}
