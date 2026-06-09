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
    inherit (self.myLib.constants) fqdn;
    inherit (lib) mkDefault;
  in {
    imports = [
      # normally, I would avoid importing cross-module, however mailserver gets an exception: the jails *rely* on the f2b emailer script within the main module
      self.nixosModules.fail2ban
      inputs.nixos-mailserver.nixosModules.mailserver
    ];
    modules.services.f2b.recidiveJail = mkDefault true;

    users.users.root.extraGroups = ["acme"];
    networking.firewall.allowedTCPPorts = [
      25 # SMTP
      465 # SUBMISSIONS
      993 # IMAPS
    ];

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

    # base admin account
    sops.secrets.adminMailPass = {};
    mailserver.accounts."admin@lament.gay" = {
      hashedPasswordFile = config.sops.secrets.adminMailPass.path;
      aliases = [
        "postmaster@lament.gay"
        "abuse@lament.gay"
        "system@lament.gay"
      ];
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

    services.fail2ban.jails = let
      action = ''
        nftables-allports
          fail2ban-email
      '';
    in {
      postfix.settings = {
        enabled = true;
        filter = "postfix[mode=aggressive]";
        port = "smtp,submissions,submission";
        action = action;
      };
      dovecot.settings = {
        enabled = true;
        filter = "dovecot[mode=aggressive]";
        port = "imap,imaps,submissions,submission";
        action = action;
        journalmatch = "_SYSTEMD_UNIT=dovecot.service";
      };
    };
  };
}
