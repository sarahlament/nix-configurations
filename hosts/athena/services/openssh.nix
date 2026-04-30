{
  config,
  lib,
  pkgs,
  ...
}: {
  networking.firewall.allowedTCPPorts = [22];

  systemd.services.sshd = {
    after = ["tailnet-online.target"];
    requires = ["tailnet-online.target"];
    serviceConfig = {
      Restart = "always";
      RestartSec = "3s";
    };
  };
}
