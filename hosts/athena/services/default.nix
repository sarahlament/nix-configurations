{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./attic.nix
    ./caddy.nix
    ./headscale.nix
    ./mailserver.nix
    ./monitoring.nix
    ./openssh.nix
    ./vaultwarden.nix
  ];
}
