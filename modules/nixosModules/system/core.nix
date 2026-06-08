{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.core = {
    config,
    lib,
    pkgs,
    ...
  }: {
    imports = with self.nixosModules; [
      inputs.home-manager.nixosModules.home-manager

      boot
      buildMachines
      networking
      nixconf
      nvf
      ssh
      sops

      rootUser
      lamentUser
    ];

    i18n.defaultLocale = "en_US.UTF-8";
    time.timeZone = "America/Chicago";
    users.defaultUserShell = pkgs.zsh;
    programs.zsh.enable = true;
    security.sudo-rs.enable = true;
    security.sudo-rs.wheelNeedsPassword = false;
    /*
    while the above is poor practice, I am confident for the following reasons:
    1: password *and* kbdinteractive auth methods are disabled, leaving only key auth
    2: sudo is restricted to @wheel, which, with nix, is fully defined by me
    3: even if the key is leaked, @wheel is denied login via public ip, so you'd need to be within the tailnet to do anything to begin with
    */

    # home-manager is a system module, so we define base options here
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "hmb";

      sharedModules = with self.homeModules; [
        btop
        fastfetch
        homeShell
        hyfetch
        posh
      ];
    };

    environment.systemPackages = with pkgs; [
      curl
    ];
  };
}
