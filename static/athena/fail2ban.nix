{
  config,
  lib,
  pkgs,
  ...
}: let
  notify = pkgs.fail2ban-email;
in {
  services.fail2ban.extraPackages = [notify];
  environment.etc."fail2ban/action.d/fail2ban-email.local".text = ''
    [Definition]
    norestored = 1
    actionban = ${notify}/bin/fail2ban-email "<name>" "<ip>" "<bantime>"
  '';
}
