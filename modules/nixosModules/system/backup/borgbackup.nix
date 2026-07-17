{ self, ... }: {
  flake.nixosModules.borgbackup =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib) mkOption types;
      inherit (self.myLib.helpers) mkBorgRepo mkSopsFile;
      inherit (self.myLib.constants) borg;
      inherit (config.networking) hostName;
      athenaSmtp = "smtp://[${self.myLib.directory.hosts.athena.ip.internal}]:25";
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
          description = "subuser for the borg box; null means this host has no state worth backing up (no job)";
          type = types.nullOr types.str;
          default = null;
        };
      };
      # a host backs up iff it's assigned a subuser; stateless hosts (e.g. the
      # runner/builder) leave it unset and get no borg job at all
      config = lib.mkIf (cfg.subuser != null) {
        sops.secrets = {
          "${cfg.subuser}Ssh".sopsFile = mkSopsFile "borg";
          "${cfg.subuser}Repo".sopsFile = mkSopsFile "borg";
        };

        programs.ssh.knownHosts.hetzner-storagebox = {
          hostNames = [ storageBox ];
          publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIICf9svRenC/PLKIL9nk6K/pxQgoiFC41wTNvoIncOxs";
        };

        systemd.services.borg-alert = {
          description = "Send email notification on borg backup failure";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = pkgs.writeShellScript "borg-alert" ''
                            ${pkgs.curl}/bin/curl \
                              --silent --show-error --connect-timeout 5 --max-time 30 \
                              --url "${athenaSmtp}" \
                              --mail-from "system@lament.gay" \
                              --mail-rcpt "admin@lament.gay" \
                              --upload-file - <<'MAIL'
              From: Borg Backup <system@lament.gay>
              To: admin@lament.gay
              Subject: [borg] backup failed on ${hostName}
              X-Notification-Source: borgbackup

              The daily borg backup job on ${hostName} failed.
              Check: journalctl -u borgbackup-job-${hostName} --since "24 hours ago"
              MAIL
            '';
          };
        };

        systemd.services."borgbackup-job-${hostName}".onFailure = [ "borg-alert.service" ];

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
