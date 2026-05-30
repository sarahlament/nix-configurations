{
  inputs,
  lib,
  self,
  ...
}: {
  flake.myLib.helpers = {
    mkReverseProxy = port: "reverse_proxy localhost:${toString port}";
    mkDisableOption = desc: lib.mkEnableOption desc // {default = true;};
  };
}
