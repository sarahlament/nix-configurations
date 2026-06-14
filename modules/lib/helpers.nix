{
  inputs,
  lib,
  self,
  ...
}: {
  flake.myLib.helpers = let
    inherit (self.myLib.constants.borg) user host;
    inherit (lib) mkEnableOption optionalAttrs;
  in {
    mkReverseProxy = port: ''
      reverse_proxy localhost:${toString port} {
        header_up X-Real-IP {remote_host}
      }
    '';
    mkBorgRepo = subuser: "ssh://${user}-${subuser}@${user}.${host}/./backup";
    mkDisableOption = desc: mkEnableOption desc // {default = true;};
    mkSopsFile = name: self + "/sops/${name}.yaml";
    mkSecret = {
      file,
      owner ? null,
      group ? null,
      mode ? null,
      reloadUnits ? null,
      restartUnits ? null,
      neededForUsers ? null,
      path ? null,
    }:
      {
        sopsFile = self + "/sops/${file}.yaml";
      }
      // optionalAttrs (owner != null) {inherit owner;}
      // optionalAttrs (group != null) {inherit group;}
      // optionalAttrs (mode != null) {inherit mode;}
      // optionalAttrs (reloadUnits != null) {inherit reloadUnits;}
      // optionalAttrs (restartUnits != null) {inherit restartUnits;}
      // optionalAttrs (neededForUsers != null) {inherit neededForUsers;}
      // optionalAttrs (path != null) {inherit path;};
  };
}
