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
    {
      sops.secrets.nixbldKey = {
        sopsFile = mkSopsFile "privkeys";
      };
      nix.distributedBuilds = true;
      # every host offloads to the builder except the builder itself (builds locally)
      nix.buildMachines = lib.mkIf (config.networking.hostName != builder.hostname) [
        {
          hostName = builder.ip.internal;
          systems = [ "x86_64-linux" ];
          protocol = "ssh-ng";
          sshUser = "nixbldRemote";
          sshKey = config.sops.secrets.nixbldKey.path;
        }
      ];
    };
}
