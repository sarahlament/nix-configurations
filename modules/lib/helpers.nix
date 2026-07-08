{
  lib,
  self,
  ...
}:
{
  flake.myLib.helpers =
    let
      inherit (self.myLib.constants.borg) user host;
    in
    {
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
        role:
        lib.findFirst (h: h.roles.${role} or false) (throw "directory: no host declares the '${role}' role")
          (lib.attrValues self.myLib.directory.hosts);
      serviceModulesFor =
        hostName:
        map (svc: self.nixosModules.${svc.module}) (
          lib.filter (svc: svc.backend == hostName) (lib.attrValues self.myLib.directory.services)
        );
    };
}
