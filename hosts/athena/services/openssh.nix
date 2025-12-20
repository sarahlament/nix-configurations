{
  config,
  lib,
  pkgs,
  ...
}: {
  networking.firewall.allowedTCPPorts = [
    22 # SSH
  ];

  services.openssh = {
    enable = true;
    listenAddresses = [
      # we only want to listen on the tailnet
      {addr = "100.64.0.1";}
      {addr = "fd7a:115c:a1e0::1";}
    ];
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  systemd.services.sshd = {
    after = ["tailnet-online.target"];
    requires = ["tailnet-online.target"];
    serviceConfig = {
      RestartSec = "10s";
      StartLimitBurst = 10;
    };
  };
}
