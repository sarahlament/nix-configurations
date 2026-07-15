{ inputs, ... }: {
  flake.nixosModules.impermanence =
    { ... }:
    {
      imports = [ inputs.impermanence.nixosModules.impermanence ];

      # /persist holds the sops age key, so it must mount before secrets decrypt.
      # every host is impermanent now, so this is unconditional.
      fileSystems."/persist".neededForBoot = true;

      environment.persistence."/persist" = {
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
