{
  lib,
  self,
  ...
}:
{
  flake.myLib.helpers =
    let
      inherit (self.myLib.constants.borg) user host;
      inherit (lib) mkEnableOption;
    in
    {
      mkReverseProxy = port: ''
        reverse_proxy localhost:${toString port} {
          header_up X-Real-IP {remote_host}
        }
      '';
      mkPrivateProxy = ip: port: ''
        bind ${ip}
        reverse_proxy localhost:${toString port} {
          header_up X-Real-IP {remote_host}
        }
      '';
      mkBorgRepo = subuser: "ssh://${user}-${subuser}@${user}.${host}/./backup";
      mkDisableOption = desc: mkEnableOption desc // { default = true; };
      mkSopsFile = name: self + "/sops/${name}.yaml";
    };
}
