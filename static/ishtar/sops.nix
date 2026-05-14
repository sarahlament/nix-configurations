{
  config,
  lib,
  pkgs,
  ...
}: {
  sops.age.keyFile = "/persist/key.age";
}
