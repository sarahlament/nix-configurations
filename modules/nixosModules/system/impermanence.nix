{ inputs, self, ... }: {
  flake.nixosModules.impermanence =
    { config, ... }:
    let
      inherit (self.myLib.directory) hosts;
      inherit (config.networking) hostName;
    in
    {
      imports = [ inputs.impermanence.nixosModules.impermanence ];

      # the store's enable is the single gate: on non-impermanent hosts the whole
      # thing is inert, so services can declare persist dirs unconditionally.
      environment.persistence."/persist" = {
        enable = hosts.${hostName}.roles.impermanent or false;
        hideMounts = true;
        directories = [
          "/var/lib/nixos" # uid/gid map - without this, static-user uids reshuffle on reboot
          "/var/lib/systemd" # random-seed, timer stamps
          {
            # every DynamicUser service keeps its StateDirectory here (alloy, etc.);
            # persist the whole tree so we don't chase each one. systemd wants 0700.
            directory = "/var/lib/private";
            mode = "0700";
          }
        ];
        files = [
          "/etc/machine-id"
        ];
      };
    };
}
