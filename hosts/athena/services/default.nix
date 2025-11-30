{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./caddy.nix
    ./headscale.nix
    ./mailserver.nix
    ./openssh.nix
    ./vaultwarden.nix
  ];
}
