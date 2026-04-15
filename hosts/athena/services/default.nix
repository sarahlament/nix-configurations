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
    ./openssh.nix
    ./vaultwarden.nix
  ];
}
