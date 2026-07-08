{ inputs, self, ... }: {
  flake.nixosModules.impermanence =
    { config, lib, ... }:
    let
      inherit (self.myLib.directory) hosts;
      inherit (config.networking) hostName;
      impermanent = hosts.${hostName}.roles.impermanent or false;
    in
    {
      imports = [ inputs.impermanence.nixosModules.impermanence ];

      # /persist holds the sops age key, so it must mount before secrets decrypt.
      # identical for every impermanent host, so it lives here, not per-host.
      fileSystems = lib.mkIf impermanent {
        "/persist".neededForBoot = true;
      };

      # the store's enable is the single gate: on non-impermanent hosts the whole
      # thing is inert, so services can declare persist dirs unconditionally.
      environment.persistence."/persist" = {
        enable = impermanent;
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
