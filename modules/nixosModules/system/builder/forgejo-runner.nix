{ self, inputs, ... }: {
  flake.nixosModules.forgejo-runner =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib) mkForce;
      inherit (self.myLib.constants) fqdn;
      inherit (self.myLib.helpers) mkSopsFile;
    in
    {
      users.groups.nixrun = { };
      users.users.nixrun = {
        isSystemUser = true;
        group = "nixrun";
        home = "/var/lib/gitea-runner/nixrun";
        createHome = true;
      };
      sops.secrets.forgejoRunnerToken = {
        sopsFile = mkSopsFile "services";
        owner = "nixrun";
        restartUnits = [ "gitea-runner-nixrun.service" ];
      };
      sops.secrets.nixbldKey = {
        sopsFile = mkSopsFile "privkeys";
        owner = "nixrun";
        path = "/var/lib/gitea-runner/nixrun/.ssh/id_ed25519";
      };

      services.gitea-actions-runner =
        let
          cfg = config.services.gitea-actions-runner.instances.nixrun;
        in
        {
          package = pkgs.forgejo-runner;
          instances.nixrun = {
            enable = true;
            name = "nixrun";
            url = "https://git.${fqdn}";
            tokenFile = config.sops.secrets.forgejoRunnerToken.path;
            labels = [ "native:host" ];
            settings = {
              server = {
                connections = {
                  forgejo = {
                    url = "https://git.${fqdn}";
                    uuid = "91e77b7a-896a-4562-a9af-becb14b936b5";
                    token_url = "file://${cfg.tokenFile}";
                    inherit (cfg) labels;
                  };
                };
              };
            };
            hostPackages = [
              inputs.deploy-rs.packages.${pkgs.stdenv.hostPlatform.system}.default
            ]
            ++ (with pkgs; [
              sudo-rs
              openssh
              nix
              nixos-rebuild
              git
              bash
              coreutils
              nixfmt-tree
              deadnix
              nodejs
            ]);
          };
        };
      systemd.services.gitea-runner-nixrun = {
        # Deploys run under this runner; a switch that bounces it would kill the in-flight CI job
        restartIfChanged = false;
        serviceConfig = {
          DynamicUser = mkForce false; # The nix store doesn't like ephemeral UIDs, so we disable the dynamic user
          User = mkForce "nixrun";
          Group = mkForce "nixrun";
          Restart = mkForce "always";
          RestartSec = mkForce "10s";
          # no MemoryMax/CPUQuota: brigid is a dedicated headless builder, let it
          # use the whole box (scale the VM if a build needs more)

          # We're using the new approach for declaring the .runner file, so we force the ExecStartPre to remove the register step
          ExecStartPre = mkForce [
            (pkgs.writeShellScript "gitea-runner-setup-nixrun" "mkdir -vp $STATE_DIRECTORY/nixrun")
          ];
        };
      };
    };
}
