{
  inputs,
  self,
  lib,
  ...
}:
let
  inherit (self.myLib.constants) fqdn;
  inherit (self.myLib.helpers) roleHost;

  # the builder host runs the CI runner that drives deploys, so it deploys itself
  # (localhost). deploy-rs's magic rollback is target-local (canary + timer on the
  # target), so self-deploy is safe - the whole fleet is a deploy node.
  builder = roleHost "builder";

  mkNode = name: host: {
    # split-horizon DNS resolves <host>.lament.gay to the WG internal address
    # when queried from inside the fleet (i.e. from the builder/runner).
    hostname = "${host.hostname}.${fqdn}";
    sshUser = "nixbldRemote";

    # the builder deploys itself, so its closure is already local - copy it
    # directly instead of round-tripping through substituters.
    fastConnection = name == builder.hostname;

    # activation runs as root via passwordless sudo (nixbldRemote is in wheel).
    profiles.system = {
      user = "root";
      path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.${name};
    };

    # activate, then require a confirmation ping back within the timeout; if the
    # box doesn't answer (lockout) or activation fails, auto-revert to the prior
    # generation. this is the unattended-safety net for the remote VPS hosts.
    magicRollback = true;
    autoRollback = true;
    confirmTimeout = 60;
  };
in
{
  flake.deploy.nodes = lib.mapAttrs mkNode self.myLib.directory.hosts;

  # schema/activation validation folded into `nix flake check`.
  perSystem =
    { system, ... }:
    {
      # deploy-rs builds + activates on the real deploy (magic rollback covers it),
      # and CI has its own build step, so keep only the cheap schema validation here -
      # drop the fleet-wide toplevel build that `deploy-activate` drags in.
      checks = lib.filterAttrs (n: _: n != "deploy-activate") (
        inputs.deploy-rs.lib.${system}.deployChecks self.deploy
      );
    };
}
