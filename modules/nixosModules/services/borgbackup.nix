{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.borgbackup = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) mkOption types;
    inherit (self.myLib.helpers) mkBorgRepo;
    inherit (config.networking) hostName;
    cfg = config.modules.services.borg;
  in {
    options.modules.services.borg = {
      subuser = mkOption {
        description = "subuser for the borg box";
        type = types.str;
      };
    };
    config = {
      sops.secrets."${cfg.subuser}Ssh" = {sopsFile = self + "/borg.yaml";};
      sops.secrets."${cfg.subuser}Repo" = {sopsFile = self + "/borg.yaml";};

      services.borgbackup.jobs.${hostName} = {
        doInit = false;
        archiveBaseName = hostName;
        repo = mkBorgRepo cfg.subuser;
        extraArgs = ["--remote-path=borg-1.4"];
        environment = {BORG_RSH = "ssh -i ${config.sops.secrets."${cfg.subuser}Ssh".path}";};
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
