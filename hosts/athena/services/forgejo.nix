{
  config,
  lib,
  pkgs,
  ...
}: { 
  users.users.gitea-runner = {
    isSystemUser = true;
    group = "gitea-runner";
    home = "/var/lib/gitea-runner/athena";
    createHome = true;
  };
  users.groups.gitea-runner = {};

  sops.secrets.forgejoRunnerToken  = {
    owner = "gitea-runner";
    group = "gitea-runner";
  };
  sops.templates.runnerEnv = {
    content = ''
      TOKEN=${config.sops.placeholder.forgejoRunnerToken}
    '';
    owner = "gitea-runner";
  };

  sops.secrets.forgejoMailPass = {};
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
    caddy.virtualHosts."http://git.athena.ts" = {
      listenAddresses = ["100.64.0.1"];
      extraConfig = ''
        reverse_proxy http://100.64.0.1:3030
      '';
    };
    forgejo = {
      enable = true;
      settings = {
        server = {
          DOMAIN = "git.athena.ts";
          ROOT_URL = "http://git.athena.ts";
          HTTP_PORT = 3030;
          HTTP_ADDR = "100.64.0.1";

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
        };
        actions.ENABLED = true;
      };
    };

    gitea-actions-runner.instances.athena = {
      enable = true;
      name = "athena";
      url = "http://100.64.0.1:3030";
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

  systemd.services.forgejo = {
    after = ["tailnet-online.target"];
    requires = ["tailnet-online.target"];
    serviceConfig = {
      EnvironmentFile = config.sops.templates.forgejoServiceEnv.path;
    };
  };
  systemd.services.gitea-runner-athena = {
    after = ["tailnet-online.target"];
    requires = ["tailnet-online.target"];
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
}
