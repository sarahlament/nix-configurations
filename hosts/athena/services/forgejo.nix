{
  config,
  lib,
  pkgs,
  ...
}: {
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
        };
        service = {
          DISABLE_REGISTRATION = false;
          REQUIRE_SIGNIN_TO_VIEW = true;
        };
        actions.ENABLED = true;
      };
    };

    gitea-actions-runner.instances.athena = {
      enable = true;
      name = "athena";
      url = "http://100.64.0.1:3030";
      tokenFile = "/var/lib/forgejo/token"; # I'll generate this and then add it to sops
      labels = [
        "native:host"
      ];
      hostPackages = with pkgs; [
        nix
        git
        bash
        coreutils
      ];
    };
  };

  systemd.services.forgejo = {
    after = ["tailnet-online.target"];
    requires = ["tailnet-online.target"];
  };
  systemd.services.gitea-runner-athena = {
    after = ["tailnet-online.target"];
    requires = ["tailnet-online.target"];
  };
}
