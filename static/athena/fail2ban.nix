{
  config,
  lib,
  pkgs,
  ...
}: {
  services.fail2ban.jails.DEFAULT.settings = {
    destemail = "admin@lament.gay";
    sender = "system-notification@lament.gay";
    sendername = "fail2ban";
    action = "%(action_mwl)s";
  };
}
