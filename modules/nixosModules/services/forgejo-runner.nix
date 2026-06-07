{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.forgejo-runner = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) mkForce;
    inherit (self.myLib.constants) fqdn;
  in {
    users.groups.nixrun = {};
    users.users.nixrun = {
      isSystemUser = true;
      group = "nixrun";
      home = "/var/lib/gitea-runner/nixrun";
      createHome = true;
    };
    sops.secrets.forgejoRunnerToken = {
      owner = "nixrun";
      group = "nixrun";
    };
    sops.secrets.nixbldKey = {
      owner = "nixrun";
      group = "nixrun";
      path = "/var/lib/gitea-runner/nixrun/.ssh/id_ed25519";
      mode = "0600";
    };

    services.gitea-actions-runner = let
      cfg = config.services.gitea-actions-runner.instances.nixrun;
    in {
      package = pkgs.forgejo-runner;
      instances.nixrun = {
        enable = true;
        name = "nixrun";
        url = "https://git.${fqdn}";
        tokenFile = config.sops.secrets.forgejoRunnerToken.path;
        labels = ["native:host"];
        settings = {
          server = {
            connections = {
              forgejo = {
                url = "https://git.lament.gay";
                uuid = "91e77b7a-896a-4562-a9af-becb14b936b5";
                token_url = "file://${cfg.tokenFile}";
                labels = cfg.labels;
              };
            };
          };
        };
        hostPackages = with pkgs; [
          sudo-rs
          openssh
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
    };
    systemd.services.gitea-runner-nixrun = {
      serviceConfig = {
        DynamicUser = mkForce false; # The nix store doesn't like ephemeral UIDs, so we disable the dynamic user
        User = mkForce "nixrun";
        Group = mkForce "nixrun";
        Restart = mkForce "always";
        RestartSec = mkForce "10s";
        MemoryMax = mkForce "2G";
        CPUQuota = mkForce "200%";

        # We're using the new approach for declaring the .runner file, so we force the ExecStartPre to remove the register step
        ExecStartPre = mkForce [
          (pkgs.writeShellScript "gitea-runner-setup-nixrun" "mkdir -vp $STATE_DIRECTORY/nixrun")
        ];
      };
    };
  };
}
