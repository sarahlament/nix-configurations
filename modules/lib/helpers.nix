{
  inputs,
  lib,
  self,
  ...
}: {
  flake.myLib = {
    mkReverseProxy = port: "reverse_proxy localhost:${toString port}";
    mkDisableOption = desc:
      lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = desc;
      };
  };
}
