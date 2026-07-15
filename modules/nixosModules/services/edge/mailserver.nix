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
      inherit (self.myLib.constants.addresses) internal;
      inherit (self.myLib.helpers) mkSopsFile;
      inherit (lib) mkDefault;
      # the constant carries the mask inside the address (addr/len); postfix wants it
      # outside the brackets ([addr]/len), so reshape it for mynetworks.
      internalPostfix =
        let
          parts = lib.splitString "/" internal;
        in
        "[${lib.head parts}]/${lib.last parts}";
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
        # every device on the WireGuard net (fleet hosts + my phone/tablet) relays
        # outbound mail through here without auth - the tunnel is the trust boundary,
        # so trust the whole internal /48 rather than listing hosts.
        postfix.settings.main.mynetworks = [
          "127.0.0.1/32"
          "[::1]/128"
          internalPostfix
        ];

        # rspamd keeps its OWN trusted-network list, separate from postfix mynetworks.
        # nixos-mailserver hardcodes it to loopback, so mail relayed over WG (vaultwarden,
        # grafana alerts) is greylisted + spam-scored as external and silently dropped by
        # non-retrying senders. trust the WG net so rspamd treats internal mail as local
        # (skips greylisting, drops the rDNS/SPF penalties, DKIM-signs it).
        rspamd.overrides."options.inc".text = lib.mkForce ''
          local_addrs = [::1/128, 127.0.0.0/8, ${internal}]
        '';

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
