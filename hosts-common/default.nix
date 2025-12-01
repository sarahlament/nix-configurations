{
  config,
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.sops-nix.nixosModules.sops

    ./boot.nix # Shared boot options
    ./nixconf.nix # 'nix' configuration
    ./packages.nix # shared packages
    ./sops.nix # sops-nix information
    ./shellTools.nix # tools for all hosts
    ./tailscale.nix # tailscale client for all my things
  ];
  system.stateVersion = "26.05";
  nixpkgs.hostPlatform = "x86_64-linux";
  nixpkgs.config = {
    allowUnfree = true;
  };
  hardware.enableRedistributableFirmware = true;
  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "America/Chicago";

  users.defaultUserShell = pkgs.zsh;
  programs.zsh.enable = true;

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hmb";
  };
}
