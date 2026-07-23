{ self, ... }:
{
  flake.nixosModules.krb5-kdc =
    { lib, ... }:
    let
      inherit (self.myLib.constants) fqdn;
      # realm is the uppercased domain, by Kerberos convention. the client config
      # (krb5.conf) rides `core` via krb5-client, so this module is server-only.
      realm = lib.toUpper fqdn;
    in
    {
      # the KDC + kadmind daemons. the module runs them but does NOT create the
      # realm database - that's a one-time `kdb5_util create -s` ceremony, after
      # which the master-key stash lets them start unattended. an empty realm body
      # takes the module's default ACL (*/admin -> all).
      services.kerberos_server = {
        enable = true;
        settings.realms.${realm} = { };
      };

      # realm database + master-key stash (.k5.LAMENT.GAY) live here. under the
      # unconditional impermanence wipe this MUST persist or the realm evaporates
      # on reboot. root:root - only the daemons ever touch it.
      environment.persistence."/persist".directories = [ "/var/lib/krb5kdc" ];
    };
}
