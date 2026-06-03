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

    # in order for my CI runner to update athena on successful merge, we need it to be able to run 'nixos-rebuild' without a password. to facilitate this, I allow that single command, and fully deny login via ssh
    services.openssh.settings.DenyUsers = ["gitea-runner"];
    security.sudo-rs.extraRules = [
      {
        users = ["gitea-runner"];
        commands = [
          {
            command = "${pkgs.nixos-rebuild}/bin/nixos-rebuild switch --flake *";
            options = ["NOPASSWD"];
          }
        ];
      }
    ];

    services.gitea-actions-runner.instances.athena = {
      enable = true;
      name = "athena";
      url = "http://127.0.0.1:3030";
      tokenFile = config.sops.secrets.forgejoRunnerToken.path;
      labels = [
        "native:host"
      ];
      hostPackages = with pkgs; [
        sudo-rs
        nix
        nixos-rebuild
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
