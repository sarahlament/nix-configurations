{
  config,
  lib,
  pkgs,
  ...
}: {
  services.github-runners = {
    renix-runner = {
      enable = true;
      user = "github-runner-renix";
      group = "github-runner-renix";
      url = "https://github.com/sarahlament/renix";
      name = "renix-runner";
      tokenFile = config.sops.secrets.githubRunnerToken.path;
      replace = true;
      extraLabels = [
        "nixos"
        "athena"
        "self-hosted"
        "linux"
        "x64"
      ];
      extraPackages = with pkgs; [
        git
        nix
        gzip
        gnutar
        bash
        coreutils
      ];
      serviceOverrides = {
        DynamicUser = lib.mkForce false; # The nix store doesn't like ephemeral UIDs, so we disable the dynamic user
        Restart = lib.mkForce "always";
        RestartSec = lib.mkForce "10s";
        MemoryMax = lib.mkForce "2G";
        CPUQuota = lib.mkForce "200%";
      };
    };
  };

  users.users.github-runner-renix = {
    isSystemUser = true;
    group = "github-runner-renix";
    home = "/var/lib/github-runner/renix-runner";
    createHome = true;
  };
  users.groups.github-runner-renix = {};
  sops.secrets.githubRunnerToken = {
    owner = "github-runner-renix";
    group = "github-runner-renix";
  };

  nix.settings = {
    allowed-users = ["github-runner-renix"];
    trusted-users = ["github-runner-renix"];
  };
}
