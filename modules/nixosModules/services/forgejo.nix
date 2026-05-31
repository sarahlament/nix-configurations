{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.forgejo = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (self.myLib.constants) fqdn;
    inherit (self.myLib.helpers) mkReverseProxy;
  in {
    sops.secrets.forgejoMailPass = {};
    sops.templates.forgejoServiceEnv = {
      content = ''
        FORGEJO__mailer__PASSWD=${config.sops.placeholder.forgejoMailPass}
      '';
      owner = "git";
    };
    mailserver.accounts = {
      "git@${fqdn}" = {
        hashedPasswordFile = config.sops.secrets.forgejoMailPass.path;
        aliases = [
          "forgejo@${fqdn}"
        ];
      };
    };

    users.groups.git = {};
    users.users.git = {
      isSystemUser = true;
      group = "git";
      home = "/var/lib/forgejo";
      shell = "${pkgs.bash}/bin/bash";
    };

    services = {
      caddy.virtualHosts."https://git.${fqdn}".extraConfig = mkReverseProxy config.services.forgejo.settings.server.HTTP_PORT;

      openssh.extraConfig = ''
        AcceptEnv GIT_PROTOCOL
        Match User git
          AuthorizedKeysCommandUser git
          AuthorizedKeysCommand ${pkgs.forgejo}/bin/forgejo keys -c /var/lib/forgejo/custom/conf/app.ini -e git -u %u -t %t -k %k
      '';
      forgejo = {
        enable = true;
        user = "git";
        settings = {
          server = {
            DOMAIN = "git.${fqdn}";
            ROOT_URL = "https://git.${fqdn}";
            LANDING_PAGE = "/sarahlament";
            HTTP_PORT = 3030;
            HTTP_ADDR = "localhost";

            SSH_DOMAIN = fqdn;
            SSH_USER = "git";
            SSH_PORT = 22;
            START_SSH_SERVER = false;
            SSH_CREATE_AUTHORIZED_KEYS_FILE = false;
          };
          repository.USE_COMPAT_SSH_URI = false;
          service = {
            DISABLE_REGISTRATION = true;
            REQUIRE_SIGNIN_TO_VIEW = false;
          };
          mailer = {
            ENABLED = true;
            PROTOCOL = "smtp";
            SMTP_ADDR = "localhost";
            FROM = "git@${fqdn}";
            USER = "git";
            PASSWD = "$__file{${config.sops.secrets.forgejoMailPass.path}}";
          };
          actions.ENABLED = true;
        };
      };
    };

    systemd.services = {
      forgejo = {
        serviceConfig = {
          EnvironmentFile = config.sops.secrets.forgejoRunnerToken.path;
        };
      };
    };
  };
}
