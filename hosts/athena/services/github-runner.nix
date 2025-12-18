{
  config,
  lib,
  pkgs,
  ...
}: {
  # GitHub Actions self-hosted runner configuration
  #
  # To set up:
  # 1. Go to your GitHub repo settings → Actions → Runners → New self-hosted runner
  # 2. Copy the registration token
  # 3. Add to sops: sops hosts-common/secrets.yaml
  #    github-runner-token: "your-registration-token-here"
  # 4. Deploy this configuration
  #
  # Note: The runner will automatically register itself on first boot.
  # You can register multiple runners by adding more entries to the runners attrset.

  services.github-runners = {
    # Main runner for the renix repository
    renix-runner = {
      enable = true;

      # Repository or organization URL
      # For a specific repo: "https://github.com/username/repo"
      # For an organization: "https://github.com/orgname"
      url = "https://github.com/sarahlament/renix";

      # Runner name that will appear in GitHub
      name = "athena-runner";

      # Path to file containing the GitHub registration token
      tokenFile = config.sops.secrets.github-runner-token.path;

      # Replace the runner if it already exists (useful for redeployment)
      replace = true;

      # Extra labels for targeting specific jobs
      extraLabels = [
        "nixos"
        "athena"
        "self-hosted"
        "linux"
        "x64"
      ];

      # Extra packages available to the runner
      extraPackages = with pkgs; [
        git
        nix
        gzip
        gnutar
        bash
        coreutils
      ];

      # Working directory for the runner
      workDir = "/var/lib/github-runners/renix-runner";

      # Service configuration
      serviceOverrides = {
        # Restart the runner if it fails
        Restart = lib.mkForce "always";
        RestartSec = lib.mkForce "10s";

        # Resource limits (optional, adjust as needed)
        MemoryMax = lib.mkForce "8G";
        CPUQuota = lib.mkForce "400%"; # 4 CPU cores worth
      };
    };
  };

  # SOPS secret for the GitHub runner token
  sops.secrets.github-runner-token = {
    owner = "github-runner";
    group = "github-runner";
  };

  # Ensure Nix is available and configured for the runner
  nix.settings = {
    # Allow the runner to use the system's trusted users
    allowed-users = ["github-runner"];

    # Allow the runner to build derivations
    trusted-users = ["github-runner"];
  };
}
