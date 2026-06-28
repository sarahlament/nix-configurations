{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.fail2ban = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) mkEnableOption mkIf;
    inherit (self.myLib.constants.addresses) internal;
    cfg = config.modules.services.f2b;
  in {
    options.modules.services.f2b.recidiveJail = mkEnableOption "Enable the recidivist jail";
    config = {
      # normally we would also define a jail here, but NixOS ships with one for sshd by default
      services.fail2ban = {
        enable = true;
        extraPackages = with pkgs; [fail2ban-email];
        bantime = "1h";
        banaction = "nftables-allports"; # knock on a door you shouldn't, get banned from all
        bantime-increment = {
          enable = true;
          overalljails = true;
        };
        ignoreIP = [internal];
        jails.recidive.settings = mkIf cfg.recidiveJail {
          enabled = true;
          filter = "recidive";
          findtime = "48h";
          bantime = "30d";
          action = ''
            nftables-allports[name=recidivist]
              fail2ban-email
          '';
        };
      };
      environment.etc."fail2ban/action.d/fail2ban-email.local".text = ''
        [Definition]
        norestored = 1
        actionban = ${pkgs.fail2ban-email}/bin/fail2ban-email "<name>" "<ip>" "<bantime>"
      '';
    };
  };
}
