{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.ssh = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) mkEnableOption mapAttrs;
    inherit (self.myLib) directory;
    inherit (self.myLib.constants.addresses) tailnet;
    cfg = config.modules.ssh;
  in {
    options.modules.ssh.public = mkEnableOption "public-facing config";
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

        # admins cannot login via public ip
        extraConfig = ''
          Match User lament,nixbldRemote Address *,!${tailnet.v4},!${tailnet.v6}
            PubkeyAuthentication no
        '';
      };

      warnings = lib.optional (cfg.public && !config.services.fail2ban.enable) "SSH is public without fail2ban enabled...";
    };
  };
}
