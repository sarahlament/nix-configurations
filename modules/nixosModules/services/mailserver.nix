{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.mailserver = {
    config,
    lib,
    pkgs,
    ...
  }: let
    fqdn = config.modules.services.caddy.fqdn;
  in {
    imports = [
      inputs.nixos-mailserver.nixosModules.mailserver
      self.nixosModules.fail2ban
    ];

    users.users.root.extraGroups = ["acme"];
    networking.firewall.allowedTCPPorts = [
      25 # SMTP
      465 # SUBMISSIONS
      993 # IMAPS
    ];

    # HTTP-only server for ACME challenges
    services.caddy.extraConfig = ''
      http://mail.${fqdn} {
        root * /var/lib/acme/acme-challenge
        file_server
      }
    '';

    security.acme = {
      acceptTerms = true;
      defaults.email = "sarah@${fqdn}";

      certs."mail.${fqdn}" = {
        webroot = "/var/lib/acme/acme-challenge";
        group = "dovecot2";
        postRun = "systemctl reload postfix dovecot2";
      };
    };

    mailserver = {
      enable = true;
      stateVersion = 3;
      fqdn = "mail.${fqdn}";
      domains = ["${fqdn}"];

      x509 = {
        certificateFile = "/var/lib/acme/mail.${fqdn}/fullchain.pem";
        privateKeyFile = "/var/lib/acme/mail.${fqdn}/key.pem";
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

    # Mail backup
    systemd.tmpfiles.rules = [
      "d /var/backup/mail 0700 root root -"
    ];

    systemd.services.mail-backup = {
      description = "Backup mail data";
      serviceConfig.Type = "oneshot";
      script = ''
        rsync -a /var/vmail/ /var/backup/mail/
      '';
      path = [pkgs.rsync];
    };

    systemd.timers.mail-backup = {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
    };

    services.fail2ban.jails = {
      postfix.settings = {
        enabled = true;
        filter = "postfix[mode=aggressive]";
        port = "smtp,submissions,submission";
        maxretry = 2;
        bantime = "72h";
      };
      dovecot2.settings = {
        enabled = true;
        filter = "dovecot[mode=aggressive]";
        port = "imap,imaps,submissions,submission";
        action = ''
          nftables-allports
            fail2ban-email
        '';
      };
    };
  };
}
