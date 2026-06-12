{
  inputs,
  lib,
  self,
  ...
}: {
  flake.myLib.helpers = let
    inherit (self.myLib.constants.borg) user host;
  in {
    mkReverseProxy = port: ''
      reverse_proxy localhost:${toString port} {
        header_up X-Real-IP {remote_host}
      }
    '';
    mkBorgRepo = subuser: "ssh://${user}-${subuser}@${user}.${host}/./backup";
    mkDisableOption = desc: lib.mkEnableOption desc // {default = true;};
  };
}
