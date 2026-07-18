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
    sshUser = "deployer";

    # the builder deploys itself, so its closure is already local - copy it
    # directly instead of round-tripping through substituters.
    fastConnection = name == builder.hostname;

    # activation runs as root via passwordless sudo (deployer is in wheel).
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
  # deploy-rs's `deployChecks` are deliberately NOT wired into `nix flake check`:
  # both deploy-schema and deploy-activate embed the fleet's realised toplevels
  # (the schema check bakes them into deploy.json via string-context), so either one
  # turns `flake check` into a full fleet build. deploy-rs builds + activates on the
  # real deploy (magic rollback covers it) and CI has its own build step, so flake
  # check stays eval-only.
  flake.deploy.nodes = lib.mapAttrs mkNode self.myLib.directory.hosts;
}
