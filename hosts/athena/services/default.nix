{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./attic.nix
    ./caddy.nix
    ./github-runner.nix
    ./headscale.nix
    ./mailserver.nix
    ./monitoring.nix
    ./openssh.nix
    ./vaultwarden.nix
  ];
}
