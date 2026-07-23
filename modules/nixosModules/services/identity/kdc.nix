{ self, ... }:
{
  flake.nixosModules.krb5-kdc =
    { config, lib, ... }:
    let
      inherit (self.myLib.constants) fqdn;
      # realm is the uppercased domain, by Kerberos convention
      realm = lib.toUpper fqdn;
      # verdandi.lament.gay - resolved to the WG internal IP by the kresd hints
      kdcHost = "${config.networking.hostName}.${fqdn}";
    in
    {
      # client config: teach the tools on this host where the realm lives. scoped
      # to the KDC host for now; increment 2 hoists this to `core` (deriving the
      # KDC via `roleHost [ "identity" ]`) so the whole fleet can kinit.
      security.krb5 = {
        enable = true;
        settings = {
          libdefaults.default_realm = realm;
          realms.${realm} = {
            kdc = kdcHost;
            admin_server = kdcHost;
          };
          domain_realm = {
            ".${fqdn}" = realm;
            ${fqdn} = realm;
          };
        };
      };

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
