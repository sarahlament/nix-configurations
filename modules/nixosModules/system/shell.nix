{inputs, ...}: {

  flake.nixosModules.shell = {
    config,
    lib,
    pkgs,
    ...
  }: {
    i18n.defaultLocale = "en_US.UTF-8";
    time.timeZone = "America/Chicago";
    users.defaultUserShell = pkgs.zsh;

    programs = {
      zsh = {
        enable = true;
        shellAliases = {
          cat = "bat";
          ls = "eza";
          la = "eza -a --grid";
          lt = "eza --tree --level=1";
          ll = "eza -l --grid";
          lla = "eza -la --grid";
          ltt = "eza --tree";
          grep = "rg --color=auto";
        };
      };

      zoxide = {
        enable = true;
        enableZshIntegration = true;
      };
    };

    environment.systemPackages = with pkgs; [
      unrar
      jq
      curl
    ];
  };
}
