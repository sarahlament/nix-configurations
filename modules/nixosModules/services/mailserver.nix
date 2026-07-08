{
  inputs,
  self,
  ...
}:
{
  flake.nixosModules.mailserver =
    {
      config,
      lib,
      ...
    }:
    let
      inherit (self.myLib.constants) fqdn;
      inherit (self.myLib.helpers) mkSopsFile;
      inherit (self.myLib.directory) hosts;
      inherit (lib) mkDefault;
    in
    {
      imports = [
        # normally, I would avoid importing cross-module, however mailserver gets an exception: the jails *rely* on the f2b emailer script within the main module
        self.nixosModules.fail2ban
        # likewise: the cert below consumes acme's rfc2136 DNS-01 defaults
        self.nixosModules.acme
        inputs.nixos-mailserver.nixosModules.mailserver
      ];
      modules.services.f2b.recidiveJail = mkDefault true;

      security.acme.certs."mail.${fqdn}" = {
        group = "dovecot2";
        extraLegoRenewFlags = [ "--reuse-key" ];
        reloadServices = [
          "postfix.service"
          "dovecot.service"
        ];
      };

      users.users.root.extraGroups = [ "acme" ];
      networking.firewall.allowedTCPPorts = [
        25 # SMTP
        465 # SUBMISSIONS
        993 # IMAPS
      ];

      mailserver = {
        enable = true;
        stateVersion = 3;
        fqdn = "mail.${fqdn}";
        domains = [ "${fqdn}" ];

        x509 = {
          useACMEHost = "mail.${fqdn}";
        };

        enableImap = false;
        enableImapSsl = true;
        enablePop3 = false;
        enablePop3Ssl = false;
        enableSubmission = false;
        enableSubmissionSsl = true;

        dkim.enable = true;
        dkim.defaults.selector = "mail";

        storage.path = "/var/vmail";

        fullTextSearch = {
          enable = false;
          memoryLimit = 500;
        };
      };

      # tmpfs root wipes these on reboot - persist the mail store and DKIM keys.
      # explicit ownership matters: a root-owned persist entry bind-mounts over
      # the service's dir and locks it out. the acme cert re-issues via DNS-01 and
      # rspamd bayes retrains, so neither is persisted here.
      environment.persistence."/persist".directories = [
        {
          directory = config.mailserver.storage.path;
          user = config.mailserver.storage.owner;
          group = config.mailserver.storage.group;
          mode = "0700";
        }
        {
          directory = config.mailserver.dkim.keyDirectory;
          user = "rspamd";
          group = "rspamd";
          mode = "0755";
        }
      ];

      # base admin account
      sops.secrets.adminMailPass = {
        sopsFile = mkSopsFile "mail";
      };
      mailserver.accounts."admin@${fqdn}" = {
        hashedPasswordFile = config.sops.secrets.adminMailPass.path;
        aliases = [
          "postmaster@${fqdn}"
          "hostmaster@${fqdn}"
          "abuse@${fqdn}"
          "system@${fqdn}"
        ];
      };

      services = {
        # fleet hosts relay outbound mail through here over WireGuard, so trust their
        # internal addresses instead of requiring auth. peers (phone/tablet) are not
        # included - only full hosts.
        postfix.settings.main.mynetworks = [
          "127.0.0.1/32"
          "[::1]/128"
        ]
        ++ map (h: "[${h.ip.internal}]/128") (lib.attrValues hosts);

        borgbackup.jobs.${config.networking.hostName}.paths = [
          config.security.acme.certs."mail.${fqdn}".directory
          config.mailserver.dkim.keyDirectory
          config.mailserver.storage.path
        ];
        fail2ban.jails =
          let
            action = ''
              nftables-allports
                fail2ban-email
            '';
          in
          {
            postfix.settings = {
              enabled = true;
              filter = "postfix[mode=aggressive]";
              port = "smtp,submissions,submission";
              inherit action;
            };
            dovecot.settings = {
              enabled = true;
              filter = "dovecot[mode=aggressive]";
              port = "imap,imaps,submissions,submission";
              journalmatch = "_SYSTEMD_UNIT=dovecot.service";
              inherit action;
            };
          };
      };
    };
}
