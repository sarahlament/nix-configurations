{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./attic.nix
    ./caddy.nix
    ./forgejo.nix
    ./headscale.nix
    ./mailserver.nix
    ./openssh.nix
    ./vaultwarden.nix
  ];
}
