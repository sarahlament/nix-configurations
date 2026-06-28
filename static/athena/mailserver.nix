{
  config,
  lib,
  pkgs,
  self,
  ...
}: let
  inherit (self.myLib.constants) fqdn;
  inherit (self.myLib.helpers) mkSopsFile;
in {
  # accounts are not module definitions
  sops.secrets.lamentMailPass = {sopsFile = mkSopsFile "pass";};
  mailserver.accounts = let
    passwords = config.sops.secrets;
  in {
    "sarah@${fqdn}" = {
      hashedPasswordFile = passwords.lamentMailPass.path;
      aliases = [
        "lament@${fqdn}"
        "sarahlament@${fqdn}"
      ];
    };
  };
}
