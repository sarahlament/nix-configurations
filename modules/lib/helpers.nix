{
  inputs,
  self,
  ...
}: {
  flake.myLib.mkReverseProxy = port: ''reverse_proxy localhost:${toString port}'';
}
