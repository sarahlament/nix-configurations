{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.sysShell = {
    config,
    lib,
    pkgs,
    ...
  }: {
    i18n.defaultLocale = "en_US.UTF-8";
    time.timeZone = "America/Chicago";
    users.defaultUserShell = pkgs.zsh;
    programs.zsh.enable = true;
    security.sudo-rs.enable = true;

    environment.systemPackages = with pkgs; [
      unrar
      jq
      curl
    ];

    home-manager.sharedModules = with self.homeModules; [
      btop
      homeShell
      kitty
      nixvim
      posh
    ];
  };
}
