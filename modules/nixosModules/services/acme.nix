{ self, ... }: {
  flake.nixosModules.acme =
    { config, ... }:
    let
      inherit (self.myLib.constants) fqdn;
    in
    {
      imports = [ self.nixosModules.tsig ];

      security.acme = {
        acceptTerms = true;
        defaults = {
          email = "sarah@${fqdn}";
          dnsProvider = "rfc2136";
          environmentFile = config.sops.templates.acmeTsig.path;
          # HE's secondaries AXFR ~30s after our NOTIFY, but lego yanks the challenge
          # TXT in ~5s - so HE always fetches a zone where it's already gone. wait a
          # fixed 90s (keeping the TXT live) so HE + LE can actually see it.
          extraLegoFlags = [ "--dns.propagation-wait=90s" ];
        };
      };

      # DANE/TLSA pins the cert key (3 1 1), so /var/lib/acme MUST persist - a fresh
      # cert key on reinstall breaks the published TLSA. matches the working
      # ownership: top dir root:root 0700, cert subdirs keep their acme:<group>.
      environment.persistence."/persist".directories = [
        {
          directory = "/var/lib/acme";
          user = "root";
          group = "root";
          mode = "0700";
        }
      ];
    };
}
