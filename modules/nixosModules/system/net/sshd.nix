{ self, ... }: {
  flake.nixosModules.ssh =
    {
      config,
      lib,
      ...
    }:
    let
      inherit (lib)
        mkEnableOption
        mkOption
        mkIf
        types
        mapAttrs
        ;
      inherit (self.myLib.directory) hosts;
      inherit (self.myLib.constants) fqdn;
      inherit (self.myLib.constants.addresses) internal;
      inherit (self.myLib.helpers) mkSopsFile;
      cfg = config.modules.ssh;
    in
    {
      options.modules.ssh = {
        public = mkEnableOption "public-facing config";
        publicUsers = mkOption {
          type = types.listOf types.str;
          default = [ ];
          example = [ "git" ];
          description = "users allowed public login";
        };
      };
      config = {
        sops.secrets."${config.networking.hostName}SshKey" = {
          sopsFile = mkSopsFile "privkeys";
          reloadUnits = [ "sshd.service" ];
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
              path = config.sops.secrets."${config.networking.hostName}SshKey".path;
            }
          ];
          knownHosts = mapAttrs (name: host: {
            hostNames = [
              name
              "${name}.${fqdn}"
              host.ip.internal
            ];
            publicKey = host.keys.sshPub;
          }) hosts;

          # admins cannot login via public ip
          extraConfig = mkIf (cfg.public && (cfg.publicUsers != [ ])) ''
            Match User ${
              lib.concatStringsSep "," ([ "*" ] ++ map (u: "!${u}") cfg.publicUsers)
            } Address *,!${internal}
              PubkeyAuthentication no
          '';
        };

        warnings = lib.optional (
          cfg.public && !config.services.fail2ban.enable
        ) "SSH is public without fail2ban enabled...";
      };
    };
}
