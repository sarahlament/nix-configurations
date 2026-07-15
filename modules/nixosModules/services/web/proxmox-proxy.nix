{ self, ... }:
{
  flake.nixosModules.proxmox-proxy =
    { config, ... }:
    let
      inherit (self.myLib.directory) hosts services;
      inherit (config.networking) hostName;
      inherit (hosts.${hostName}) ip;
      inherit (services.proxmox) port;
    in
    {
      # minerva is a guest on this proxmox host, so it reaches the hypervisor
      # natively on its physical LAN. terminate proxmox's self-signed TLS here
      # and re-expose plain http on the WG internal iface for athena's edge caddy.
      services.caddy = {
        enable = true;
        virtualHosts."http://:${toString port}".extraConfig = ''
          bind ${ip.internal}
          reverse_proxy https://192.168.4.236:8006 {
            transport http {
              tls_insecure_skip_verify
            }
            header_up X-Real-IP {remote_host}
          }
        '';
      };
    };
}
