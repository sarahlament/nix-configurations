{ self, ... }:
{
  # fleet-wide Kerberos client config: every host learns the realm + KDC so it
  # can kinit and request service tickets. rides `core`. the KDC host itself
  # (the `identity` role) gets this too, so kdc.nix carries no client config.
  flake.nixosModules.krb5-client =
    { lib, ... }:
    let
      inherit (self.myLib.constants) fqdn;
      inherit (self.myLib.helpers) roleHost;
      realm = lib.toUpper fqdn;
      # the host declaring the `identity` role - verdandi - resolved by kresd hints
      kdcHost = "${(roleHost [ "identity" ]).hostname}.${fqdn}";
    in
    {
      security.krb5 = {
        enable = true;
        settings = {
          libdefaults = {
            default_realm = realm;
            # WG hosts have no reverse DNS; skip the PTR lookup + canonicalization
            # so GSSAPI uses the name as given instead of SERVFAILing on a missing
            # PTR. Kerberos is notoriously DNS-brittle - these are the usual cure.
            rdns = false;
            dns_canonicalize_hostname = false;
          };
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
    };
}
