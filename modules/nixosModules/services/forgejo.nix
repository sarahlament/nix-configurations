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
    inherit (self.myLib.helpers) mkReverseProxy mkSopsFile;
  in {
    sops.secrets.forgejoMailPass = {sopsFile = mkSopsFile "pass";};
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

    # I've shamelessly stolen catppuccin's config for their themes here
    systemd.tmpfiles.settings."10-catppuccin-forgejo-theme" = let
      cfg = config.services.forgejo;
      inherit (cfg) customDir;
    in {
      "${customDir}/public/assets/css"."C+" = {argument = toString pkgs.forgejo-themes;};
      "${customDir}/public/assets".d = {inherit (cfg) user group;};
      "${customDir}/public".d = {inherit (cfg) user group;};
    };
    services = {
      caddy.virtualHosts."https://git.${fqdn}".extraConfig = mkReverseProxy config.services.forgejo.settings.server.HTTP_PORT;
      borgbackup.jobs.${config.networking.hostName} = {
        preHook = "systemctl start forgejo-dump.service";
        paths = [config.services.forgejo.dump.backupDir];
      };

      forgejo = {
        enable = true;
        user = "git";
        dump = {
          enable = true;
          backupDir = "/var/backup/forgejo";
          type = "tar";
          file = "forgejo-dump";
        };
        settings = {
          DEFAULT = {
            APP_NAME = "git";
            APP_SLOGAN = "just the code";
          };
          repository = {
            PREFERED_LICENSES = "MIT";
            USE_COMPAT_SSH_URI = false;
            GO_GET_CLONE_URL_PROTOCOL = "ssh";
            ENABLE_PUSH_CREATE_USER = true;
            DISABLE_STARS = true;
            DISABLE_FORKS = true;
          };
          ui = let
            theme = "catppuccin-mocha-mauve";
          in {
            DEFAULT_THEME = theme;
            THEMES = theme;
          };
          "ui.meta" = {
            AUTHOR = "Sarah Lament";
            DESCRIPTION = "just the code";
          };
          server = {
            DOMAIN = "git.${fqdn}";
            ROOT_URL = "https://git.${fqdn}";
            LANDING_PAGE = "/sarahlament";
            HTTP_PORT = 3030;
            HTTP_ADDR = "localhost";

            SSH_DOMAIN = "athena.ts";
            SSH_USER = "git";
            SSH_PORT = 22;
            START_SSH_SERVER = false;
            SSH_CREATE_AUTHORIZED_KEYS_FILE = true;
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
