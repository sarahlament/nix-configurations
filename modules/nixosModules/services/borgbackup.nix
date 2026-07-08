{ self, ... }: {
  flake.nixosModules.borgbackup =
    {
      config,
      lib,
      ...
    }:
    let
      inherit (lib) mkOption types;
      inherit (self.myLib.helpers) mkBorgRepo mkSopsFile;
      inherit (self.myLib.constants) borg;
      inherit (config.networking) hostName;
      cfg = config.modules.services.borg;
      # the storage box's own ssh host key, so non-interactive borg-over-ssh trusts
      # it without a manual accept - critical on impermanent hosts whose
      # /root/.ssh/known_hosts is wiped every boot (this is why minerva silently
      # failed while athena, with a persisted known_hosts, worked)
      storageBox =
        let
          parts = lib.splitString ":" borg.host;
        in
        "[${borg.user}.${lib.head parts}]:${lib.last parts}";
    in
    {
      options.modules.services.borg = {
        subuser = mkOption {
          description = "subuser for the borg box";
          type = types.str;
        };
      };
      config = {
        sops.secrets."${cfg.subuser}Ssh" = {
          sopsFile = mkSopsFile "borg";
        };
        sops.secrets."${cfg.subuser}Repo" = {
          sopsFile = mkSopsFile "borg";
        };

        programs.ssh.knownHosts.hetzner-storagebox = {
          hostNames = [ storageBox ];
          publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIICf9svRenC/PLKIL9nk6K/pxQgoiFC41wTNvoIncOxs";
        };

        services.borgbackup.jobs.${hostName} = {
          doInit = false;
          archiveBaseName = hostName;
          repo = mkBorgRepo cfg.subuser;
          extraArgs = [ "--remote-path=borg-1.4" ];
          environment = {
            BORG_RSH = "ssh -i ${config.sops.secrets."${cfg.subuser}Ssh".path}";
          };
          compression = "auto,zstd";
          startAt = "daily";
          prune.keep = {
            daily = 7;
            weekly = 4;
            monthly = 6;
          };
          exclude = [
            "**/.cache"
          ];
          encryption = {
            mode = "repokey-blake2";
            passCommand = "cat ${config.sops.secrets."${cfg.subuser}Repo".path}";
          };
        };
      };
    };
}
