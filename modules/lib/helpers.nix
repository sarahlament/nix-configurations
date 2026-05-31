{
  inputs,
  lib,
  self,
  ...
}: {
  flake.myLib.helpers = {
    mkReverseProxy = port: ''
      reverse_proxy localhost:${toString port} {
        header_up X-Real-IP {remote_host}
      }
    '';
    mkDisableOption = desc: lib.mkEnableOption desc // {default = true;};
  };
}
