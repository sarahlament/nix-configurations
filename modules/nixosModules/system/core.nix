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
      boot
      networking
      nixconf
      nvf
      sops
    ];

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
  };
}
