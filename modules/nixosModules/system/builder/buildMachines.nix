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
      pkgs,
      ...
    }:
    let
      inherit (lib) mkIf mkForce;
      onBuilder = config.networking.hostName == builder.hostname;
    in
    {
      # build user: SSH target on brigid for build offload - non-wheel, trusted by nix
      users.groups.builder = mkIf onBuilder { };
      users.users.builder = mkIf onBuilder {
        isSystemUser = true;
        group = "builder";
        home = "/var/lib/builder/";
        createHome = true;
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBxBpDo3TnNztJUEp8mKh4FeZlnZcm76PTrkrQhNm+70 builder@pantheon"
        ];
        shell = pkgs.bash;
      };

      # build key: outbound SSH credential on non-builder hosts to reach brigid
      sops.secrets.builderKey = mkIf (!onBuilder) {
        sopsFile = mkSopsFile "privkeys";
      };

      nix = {
        distributedBuilds = true;
        # every host offloads to the builder except the builder itself (builds locally)
        buildMachines = mkIf (!onBuilder) [
          {
            hostName = builder.ip.internal;
            systems = [ "x86_64-linux" ];
            protocol = "ssh-ng";
            sshUser = "builder";
            sshKey = config.sops.secrets.builderKey.path;
          }
        ];

        # keep the build cache warm on the builder: retain the derivations and
        # outputs of anything rooted so CI re-runs hit the store instead of
        # rebuilding/refetching the world. --keep N only guards profile
        # generations, so this is the piece that actually preserves cache.
        settings = mkIf onBuilder {
          keep-outputs = true;
          keep-derivations = true;
          trusted-users = [ "builder" ];
        };
      };

      # and clean less eagerly than the fleet default (--keep 3, weekly)
      programs.nh.clean = mkIf onBuilder {
        extraArgs = mkForce "--keep 5 --optimise";
        dates = mkForce "monthly";
      };
    };
}
