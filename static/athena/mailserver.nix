{
  config,
  lib,
  pkgs,
  ...
}: {
  sops.secrets.adminMailPass = {};
  sops.secrets.lamentMailPass = {};
  mailserver.accounts = let
    passwords = config.sops.secrets;
  in {
    "sarah@lament.gay" = {
      hashedPasswordFile = passwords.lamentMailPass.path;
      aliases = [
        "lament@lament.gay"
        "sarahlament@lament.gay"
      ];
    };
    "admin@lament.gay" = {
      hashedPasswordFile = passwords.adminMailPass.path;
      aliases = [
        "postmaster@lament.gay"
        "abuse@lament.gay"
        "system@lament.gay"
      ];
    };
  };
}
