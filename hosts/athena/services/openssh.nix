{
  config,
  lib,
  pkgs,
  ...
}: {
  services.openssh.listenAddresses = [
    # we only want to listen on the tailnet
    {addr = "100.64.0.1";}
    {addr = "fd7a:115c:a1e0::1";}
  ];

  systemd.services.sshd = {
    after = ["tailnet-online.target"];
    requires = ["tailnet-online.target"];
    serviceConfig = {
      Restart = "always";
      RestartSec = "3s";
    };
  };
}
