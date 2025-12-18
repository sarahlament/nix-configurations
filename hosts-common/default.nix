{
  config,
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.disko.nixosModules.disko
    inputs.home-manager.nixosModules.home-manager
    inputs.sops-nix.nixosModules.sops

    ./boot.nix # Shared boot options
    ./network.nix # basic network configuration
    ./nixconf.nix # 'nix' configuration
    ./packages.nix # shared packages
    ./sops.nix # sops-nix information
    ./shellTools.nix # tools for all hosts

    ./modules # reusable modules in case I need them

    ../users/lament # I'm obviously going to be on all of my systems
  ];
  system.stateVersion = "26.05";
  nixpkgs.hostPlatform = "x86_64-linux";
  nixpkgs.config = {
    allowUnfree = true;
  };
  security.sudo-rs.wheelNeedsPassword = false;
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
