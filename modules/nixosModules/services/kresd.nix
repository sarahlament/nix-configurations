{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.kresd = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (self.myLib.constants.addresses) tailnet;
  in {
    services.resolved.enable = lib.mkForce false;
    services.kresd = {
      enable = true;
      listenPlain = ["127.0.0.1:53" "[::1]:53"];
      extraConfig = ''
        tailnetDomain = policy.todnames({'${tailnet.domain}'})
        policy.add(policy.suffix(
          policy.FLAGS({'NO_CACHE'}),
          tailnetDomain
        ))
        policy.add(policy.suffix(
          policy.STUB({'100.100.100.100'}),
          tailnetDomain
        ))
      '';
    };
  };
}
