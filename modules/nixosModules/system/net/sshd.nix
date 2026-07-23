{ self, ... }: {
  flake.nixosModules.ssh =
    {
      config,
      lib,
      pkgs,
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
          sopsFile = mkSopsFile "privkeys/${config.networking.hostName}";
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
            # ticket-based login: a host with a host/<fqdn> keytab accepts a valid
            # service ticket in lieu of a key. needs a keytab at /etc/krb5.keytab.
            GSSAPIAuthentication = true;
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

        # stock openssh lacks GSSAPI; this variant carries the krb5 patches so
        # GSSAPIAuthentication is a valid option. programs.ssh.package sets the
        # CLIENT (into corePackages); services.openssh.package defaults to it, so
        # this single setting covers both the `ssh` client and sshd.
        programs.ssh = {
          package = pkgs.openssh_gssapi;
          # offer GSSAPI only to fleet hosts (short name + fqdn), so we don't burn
          # a Kerberos round-trip against github and friends.
          extraConfig = ''
            Host ${lib.concatStringsSep " " (lib.attrNames hosts)} *.${fqdn}
              GSSAPIAuthentication yes
          '';
        };

        warnings = lib.optional (
          cfg.public && !config.services.fail2ban.enable
        ) "SSH is public without fail2ban enabled...";
      };
    };
}
