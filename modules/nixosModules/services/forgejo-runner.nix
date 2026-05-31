{inputs, ...}: {
  flake.nixosModules.forgejo-runner = {
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
    sops.secrets.forgejoRunnerToken = {
      owner = "gitea-runner";
      group = "gitea-runner";
    };
    nix.settings = {
      allowed-users = ["gitea-runner"];
    };

    services.gitea-actions-runner.instances.athena = {
      enable = true;
      name = "athena";
      url = "http://127.0.0.1:3030";
      tokenFile = config.sops.secrets.forgejoRunnerToken.path;
      labels = [
        "native:host"
      ];
      hostPackages = with pkgs; [
        nix
        git
        bash
        coreutils
        alejandra
        deadnix
        nodejs
      ];
    };
    systemd.services.gitea-runner-athena = {
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
}
