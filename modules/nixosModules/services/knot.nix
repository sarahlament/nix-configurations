{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.knot = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (self.myLib.constants) fqdn;
    inherit (self.myLib.constants.addresses) nameserver;
    inherit (self.myLib.constants.addresses.public) athena;
    inherit (self.myLib.helpers) mkSopsFile;
    zoneFile = self + "/static/${fqdn}/zone";
  in {
    sops.secrets = {
      tsigSecret = {sopsFile = mkSopsFile "domain";};
      axfrSecret = {sopsFile = mkSopsFile "domain";};
    };
    sops.templates.knotTsig = {
      owner = "knot";
      content = ''
        key:
          - id: acme-rfc2136.
            algorithm: hmac-sha256
            secret: ${config.sops.placeholder.tsigSecret}
          - id: lament.he-axfr.
            algorithm: hmac-sha256
            secret: ${config.sops.placeholder.axfrSecret}
      '';
    };
    services.knot = {
      enable = true;

      keyFiles = [config.sops.templates.knotTsig.path];
      settings = {
        log.syslog.any = "info";
        server = {
          listen = ["${athena.v4}@53" "${athena.v6}@53" "127.0.0.1@5353" "::1@5353"];
          automatic-acl = false;
        };
        database.storage = "/var/lib/knot";
        remote.external = {
          address = ["${nameserver.notify.v4}@53" "${nameserver.notify.v6}@53"];
        };

        acl = {
          external-xfr = {
            action = "transfer";
            address = ["${nameserver.secondary.v4}" "${nameserver.secondary.v6}"];
            key = ["lament.he-axfr."];
          };
          local-xfr = {
            action = "transfer";
            address = ["127.0.0.1" "::1"];
          };
          acme-update = {
            action = "update";
            key = ["acme-rfc2136."];
            update-type = ["TXT"];
            update-owner = "name";
            update-owner-match = "pattern";
            update-owner-name = ["_acme-challenge" "_acme-challenge.*"];
          };
        };
        policy.domain_zsk = {
          algorithm = "ecdsap256sha256";
          zsk-lifetime = "30d";
          ksk-lifetime = "0";
          dnskey-ttl = "300";
          zone-max-ttl = "300";
          propagation-delay = "1h";
          rrsig-lifetime = "14d";
          rrsig-refresh = "7d";
        };
        zone."${fqdn}" = {
          file = "${zoneFile}";
          storage = "/var/lib/knot";
          zonefile-load = "difference-no-serial";
          zonefile-sync = "-1";
          journal-content = "all";
          dnssec-signing = true;
          dnssec-policy = "domain_zsk";
          serial-policy = "dateserial";
          notify = ["external"];
          acl = ["external-xfr" "local-xfr" "acme-update"];
        };
      };
    };

    networking.firewall.extraInputRules = ''
      ip  saddr { ${nameserver.secondary.v4}, ${nameserver.notify.v4} } tcp dport 53 accept
      ip  saddr { ${nameserver.secondary.v4}, ${nameserver.notify.v4} } udp dport 53 accept
      ip6 saddr { ${nameserver.secondary.v6}, ${nameserver.notify.v6} } tcp dport 53 accept
      ip6 saddr { ${nameserver.secondary.v6}, ${nameserver.notify.v6} } udp dport 53 accept
    '';
  };
}
