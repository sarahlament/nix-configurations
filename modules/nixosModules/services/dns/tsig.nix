{ self, ... }: {
  # imported by knot, acme, and caddy; the key collapses the repeated
  # imports into a single instance so the template isn't merged N times
  flake.nixosModules.tsig = {
    key = "tsig";
    imports = [
      (
        { config, ... }:
        let
          inherit (self.myLib.helpers) mkSopsFile;
        in
        {
          sops.secrets.tsigSecret.sopsFile = mkSopsFile "domain";
          sops.templates.acmeTsig.content = ''
            RFC2136_NAMESERVER=127.0.0.1:5353
            RFC2136_TSIG_KEY=acme-rfc2136
            RFC2136_TSIG_ALGORITHM=hmac-sha256.
            RFC2136_TSIG_SECRET=${config.sops.placeholder.tsigSecret}
          '';
        }
      )
    ];
  };
}
