{ self, ... }:
let
  inherit (self.myLib.helpers) mkSopsFile roleHost;
  # runner + remote builder live together on whichever host holds the builder role
  builder = roleHost "builder";
in
{
  flake.nixosModules.buildMachines =
    {
      config,
      lib,
      ...
    }:
    let
      inherit (lib) mkIf mkForce;
      onBuilder = config.networking.hostName == builder.hostname;
    in
    {
      sops.secrets.nixbldKey = {
        sopsFile = mkSopsFile "privkeys";
      };
      nix = {
        distributedBuilds = true;
        # every host offloads to the builder except the builder itself (builds locally)
        buildMachines = mkIf (config.networking.hostName != builder.hostname) [
          {
            hostName = builder.ip.internal;
            systems = [ "x86_64-linux" ];
            protocol = "ssh-ng";
            sshUser = "nixbldRemote";
            sshKey = config.sops.secrets.nixbldKey.path;
          }
        ];

        # keep the build cache warm on the builder: retain the derivations and
        # outputs of anything rooted so CI re-runs hit the store instead of
        # rebuilding/refetching the world. --keep N only guards profile
        # generations, so this is the piece that actually preserves cache.
        settings = mkIf onBuilder {
          keep-outputs = true;
          keep-derivations = true;
        };
      };

      # and clean less eagerly than the fleet default (--keep 3, weekly)
      programs.nh.clean = mkIf onBuilder {
        extraArgs = mkForce "--keep 5 --optimise";
        dates = mkForce "monthly";
      };
    };
}
