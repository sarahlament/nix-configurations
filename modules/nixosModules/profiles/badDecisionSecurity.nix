{inputs, ...}: {
  flake.nixosModules.badDecisionSecurity = {
    config,
    lib,
    pkgs,
    ...
  }: {
    security.sudo-rs.enable = true;
    security.sudo-rs.wheelNeedsPassword = false;
  };
}
