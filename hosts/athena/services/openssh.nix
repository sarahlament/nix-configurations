{
  config,
  lib,
  pkgs,
  ...
}: {
  networking.firewall.allowedTCPPorts = [
    22 # SSH
  ];

  services.openssh.listenAddresses = [
    # we only want to listen on the tailnet
    {addr = "100.64.0.1";}
    {addr = "fd7a:115c:a1e0::1";}
  ];
}
