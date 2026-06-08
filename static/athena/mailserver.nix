{
  config,
  lib,
  pkgs,
  ...
}: {
  # accounts are not module definitions
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
  };
}
