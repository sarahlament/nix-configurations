{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./caddy.nix
    ./headscale.nix
    ./mailserver.nix
    ./monitoring.nix
    ./openssh.nix
    ./vaultwarden.nix
  ];
}
