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

  # Make SSHD wait for Tailscale interface to be up
  systemd.services.sshd = {
    after = ["tailscaled.service" "network-online.target"];
    wants = ["tailscaled.service" "network-online.target"];
  };
}
