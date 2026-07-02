{ self, ... }: {
  flake.nixosModules.acme =
    { config, ... }:
    let
      inherit (self.myLib.constants) fqdn;
    in
    {
      sops = {
        templates.acmeTsig.content = ''
          RFC2136_NAMESERVER=127.0.0.1:5353
          RFC2136_TSIG_KEY=acme-rfc2136
          RFC2136_TSIG_ALGORITHM=hmac-sha256.
          RFC2136_TSIG_SECRET=${config.sops.placeholder.tsigSecret}
        '';
      };

      security.acme = {
        acceptTerms = true;
        defaults = {
          email = "sarah@${fqdn}";
          dnsProvider = "rfc2136";
          environmentFile = config.sops.templates.acmeTsig.path;
        };
      };
    };
}
