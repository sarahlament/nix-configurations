{
  lib,
  self,
  ...
}:
{
  flake.myLib.helpers =
    let
      inherit (self.myLib.constants.borg) user host;
      # resolve a directory node's WG port: per-host override, else fleet default
      portOf = node: node.ip.public.port or self.myLib.constants.wgPort;
    in
    {
      inherit portOf;
      # a WireGuard peer entry for a directory node: routing restricted to its own
      # /128, plus its endpoint + a keepalive if it's an entry point (publicly
      # dialable) - so the caller dials it directly rather than wait to be reached.
      mkPeer =
        node:
        {
          publicKey = node.keys.wgPub;
          allowedIPs = [ "${node.ip.internal}/128" ];
        }
        // lib.optionalAttrs (node.ip ? public) {
          endpoint = "${node.ip.public.v4}:${toString (portOf node)}";
          persistentKeepalive = 25;
        };

      mkReverseProxy =
        {
          host ? "localhost",
          port,
          bindTo ? null,
        }:
        let
          # caddy needs bracket syntax for a literal IPv6 upstream
          upstream = if lib.hasInfix ":" host then "[${host}]" else host;
        in
        lib.optionalString (bindTo != null) "bind ${bindTo}\n"
        + ''
          reverse_proxy ${upstream}:${toString port} {
            header_up X-Real-IP {remote_host}
          }
        '';
      mkBorgRepo = subuser: "ssh://${user}-${subuser}@${user}.${host}/./backup";
      mkSopsFile = name: self + "/sops/${name}.yaml";
      # the (single) host in the directory that declares a given role
      roleHost =
        path:
        let
          p = lib.toList path;
        in
        lib.findFirst (h: lib.attrByPath p false h.roles)
          (throw "directory: no host declares the '${lib.concatStringsSep "." p}' role")
          (lib.attrValues self.myLib.directory.hosts);
      serviceModulesFor =
        hostName:
        map (svc: self.nixosModules.${svc.module}) (
          lib.filter (svc: svc.backend == hostName) (lib.attrValues self.myLib.directory.services)
        );
      # role (concept) -> the modules (impl) it pulls onto whichever host declares it
      roleModulesFor =
        hostName:
        let
          roles = self.myLib.directory.hosts.${hostName}.roles or { };
          roleModules = with self.nixosModules; {
            dns.authority = [ knot ];
            dns.resolver = [ kresd ];
            edge.web = [ caddy ];
            edge.mail = [ mailserver ];
            builder = [ forgejo-runner ];
            postgres = [ postgres ];
            # edge.vpn is networking-only (the WG hub), no module to import
          };
          # walk the map: a list leaf is pulled in when the host declares the
          # matching role path; branches recurse (so nested + flat roles coexist)
          collect =
            path: node:
            if lib.isList node then
              lib.optionals (lib.attrByPath path false roles) node
            else
              lib.concatLists (lib.mapAttrsToList (k: v: collect (path ++ [ k ]) v) node);
        in
        collect [ ] roleModules;
    };
}
