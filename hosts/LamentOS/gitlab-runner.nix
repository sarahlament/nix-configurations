{
  config,
  pkgs,
  lib,
  ...
}: {
  sops.secrets.gitlabRunner = {
    owner = "lament";
    group = "users";
    mode = "0400";
  };

  services.gitlab-runner = {
    enable = true;

    extraPackages = with pkgs; [
      git
      nix
      bash
      coreutils
      findutils
      gnutar
      gzip
      openssh
      alejandra
    ];

    settings = {
      concurrent = 2;
      check_interval = 10;
    };

    services = {
      lamentos-runner = {
        description = "Atelier CI";

        executor = "shell";

        buildsDir = "/var/lib/gitlab-runner/builds";

        environmentVariables = {
          NIX_PATH = "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos";
          PATH = lib.makeBinPath (config.services.gitlab-runner.extraPackages
            ++ [
              pkgs.bash
              pkgs.coreutils
              pkgs.findutils
              pkgs.gnugrep
              pkgs.gnused
            ]);
        };

        # Contains CI_SERVER_URL and CI_SERVER_TOKEN
        authenticationTokenConfigFile = config.sops.secrets.gitlabRunner.path;
      };
    };

    gracefulTermination = true;
  };
}
