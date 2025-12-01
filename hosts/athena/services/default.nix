{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: {
  imports = [
    inputs.stylix.nixosModules.stylix

    ./caddy.nix
    ./headscale.nix
    ./mailserver.nix
    ./monitoring.nix
    ./nextcloud.nix
    ./openssh.nix
    ./vaultwarden.nix
  ];
}
