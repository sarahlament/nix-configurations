{
  config,
  lib,
  pkgs,
  ...
}: {
  users.users.root.extraGroups = ["acme"];
  networking.firewall.allowedTCPPorts = [
    25 # SMTP
    587 # SMTP submission
    993 # IMAP
  ];

  security.acme = {
    acceptTerms = true;
    defaults.email = "sarah1@lament.gay";

    certs."mail.lament.gay" = {
      webroot = "/var/lib/acme/acme-challenge";
      group = "dovecot2";
      postRun = "systemctl reload postfix dovecot2";
    };
  };

  mailserver = {
    enable = true;
    stateVersion = 3;
    fqdn = "mail.lament.gay";
    domains = ["lament.gay"];

    loginAccounts = {
      "sarah@lament.gay" = {
        hashedPasswordFile = config.sops.secrets.lamentPassHash.path;
        aliases = [
          "postmaster@lament.gay"
          "admin@lament.gay"
          "abuse@lament.gay"
        ];
      };
    };

    certificateScheme = "manual";
    certificateFile = "/var/lib/acme/mail.lament.gay/fullchain.pem";
    keyFile = "/var/lib/acme/mail.lament.gay/key.pem";

    enableImap = true;
    enableImapSsl = true;
    enablePop3 = false;
    enablePop3Ssl = false;
    enableSubmission = true;
    enableSubmissionSsl = true;

    dkimSigning = true;
    dkimSelector = "mail";

    mailDirectory = "/var/vmail";

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
}
