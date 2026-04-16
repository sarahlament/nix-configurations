{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./caddy.nix
    ./forgejo.nix
    ./headscale.nix
    ./mailserver.nix
    ./monitoring.nix
    ./openssh.nix
    ./vaultwarden.nix
  ];
}
