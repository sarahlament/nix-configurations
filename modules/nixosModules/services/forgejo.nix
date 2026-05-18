{inputs, ...}: {
  flake.nixosModules.forgejo = {
    config,
    lib,
    pkgs,
    ...
  }: let
    fqdn = config.modules.services.caddy.fqdn;
  in {
    sops.secrets.forgejoMailPass = {};
    mailserver.accounts = let
      passwords = config.sops.secrets;
    in {
      "git@${fqdn}" = {
        hashedPasswordFile = passwords.forgejoMailPass.path;
        aliases = [
          "forgejo@${fqdn}"
        ];
      };
    };

    users.users.gitea-runner = {
      isSystemUser = true;
      group = "gitea-runner";
      home = "/var/lib/gitea-runner/athena";
      createHome = true;
    };
    users.groups.gitea-runner = {};

    sops.secrets.forgejoRunnerToken = {
      owner = "gitea-runner";
      group = "gitea-runner";
    };
    sops.templates.runnerEnv = {
      content = ''
        TOKEN=${config.sops.placeholder.forgejoRunnerToken}
      '';
      owner = "gitea-runner";
    };

    sops.templates.forgejoServiceEnv = {
      content = ''
        FORGEJO__mailer__PASSWD=${config.sops.placeholder.forgejoMailPass}
      '';
      owner = "forgejo";
    };

    nix.settings = {
      allowed-users = ["gitea-runner"];
      trusted-users = ["gitea-runner"];
    };

    services = {
      forgejo = {
        enable = true;
        settings = {
          server = {
            DOMAIN = "git.athena.ts";
            ROOT_URL = "http://git.athena.ts";
            HTTP_PORT = 3030;
            HTTP_ADDR = "127.0.0.1";

            SSH_DOMAIN = "git.athena.ts";
            SSH_PORT = 2222;
            START_SSH_SERVER = true;
            BUILTIN_SSH_SERVER_USER = "git";
          };
          service = {
            DISABLE_REGISTRATION = true;
            REQUIRE_SIGNIN_TO_VIEW = false;
          };
          mailer = {
            ENABLED = true;
            PROTOCOL = "smtp";
            SMTP_ADDR = "localhost";
            FROM = "git@lament.gay";
            USER = "git";
            PASSWD = "$__file{${config.sops.secrets.forgejoMailPass.path}}";
          };
          actions.ENABLED = true;
        };
      };

      gitea-actions-runner.instances.athena = {
        enable = true;
        name = "athena";
        url = "http://127.0.0.1:3030";
        tokenFile = config.sops.templates.runnerEnv.path;
        labels = [
          "native:host"
        ];
        hostPackages = with pkgs; [
          nix
          git
          bash
          coreutils
          alejandra
        ];
      };
    };

    systemd.services = {
      forgejo = {
        serviceConfig = {
          EnvironmentFile = config.sops.templates.forgejoServiceEnv.path;
        };
      };
      gitea-runner-athena = {
        serviceConfig = {
          DynamicUser = lib.mkForce false; # The nix store doesn't like ephemeral UIDs, so we disable the dynamic user
          User = "gitea-runner";
          Group = "gitea-runner";
          Restart = lib.mkForce "always";
          RestartSec = lib.mkForce "10s";
          MemoryMax = lib.mkForce "2G";
          CPUQuota = lib.mkForce "200%";
        };
      };
    };
  };
}
