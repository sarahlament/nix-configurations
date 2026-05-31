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
          DEFAULT = {
            APP_NAME = "git.lament";
            APP_SLOGAN = "gay, just like me";
          };
          repository = {
            PREFERED_LICENSES = "MIT";
            USE_COMPAT_SSH_URI = false;
            GO_GET_CLONE_URL_PROTOCOL = "ssh";
            ENABLE_PUSH_CREATE_USER = true;
            DISABLE_STARS = true;
            DISABLE_FORKS = true;
          };
          "ui.meta" = {
            AUTHOR = "Sarah Lament";
            DESCRIPTION = "gay, just like me";
          };
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
          service = {
            DISABLE_REGISTRATION = true;
            REQUIRE_SIGNIN_TO_VIEW = false;
          };
          mailer = {
            ENABLED = true;
            PROTOCOL = "smtp";
            SMTP_ADDR = "127.0.0.1";
            SMTP_PORT = 25;
            FROM = "git@${fqdn}";
            USER = "git";
            PASSWD = "file:${config.sops.secrets.forgejoMailPass.path}";
          };
          actions.ENABLED = true;
        };
      };
    };
  };
}
