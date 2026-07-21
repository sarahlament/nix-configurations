{ ... }: {
  flake.myLib.directory = {
    hosts = {
      athena = {
        hostname = "athena";
        ip = {
          internal = "fd67:d6a7:d6f3::1";
          public = {
            v4 = "104.200.16.195";
            v6 = "2600:3c00::2000:31ff:fe65:8d63";
          };
        };
        keys = {
          sshPub = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGkJt8Fdv4oR79C3wNB0IQBXD//OWu3sH0I1r5JYMaM3";
          wgPub = "3tPScod8UQO9f4KGXRGQDOSh30XEVeq/pOjkjBQ/LEM=";
        };
        roles = {
          edge = {
            vpn = true;
            web = true;
            mail = true;
          };
          dns = {
            authority = true;
            resolver = true;
          };
        };
      };
      ishtar = {
        hostname = "ishtar";
        ip = {
          internal = "fd67:d6a7:d6f3::2";
          # WG entry point: the whole fleet dials ishtar directly (router forwards
          # :51820 -> 192.168.1.15) instead of hairpinning via athena. hestia is
          # behind this same router, so it reuses these public IPs on its own port.
          public = {
            v4 = "47.32.246.158";
            v6 = "2600:6c56:7008:200:94a2:3f0d:ccbb:f89e";
            port = 51820;
          };
        };
        keys = {
          sshPub = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA8zVl6CUXd4tEb1zpdbV1SMB7taFSg+3Y3QJksY9+vU";
          wgPub = "2/eP72pROfrKRSrxPKeoroVtq9K+jvz1T4Gl4tPg03c=";
        };
        roles = {
        };
      };
      minerva = {
        hostname = "minerva";
        ip.internal = "fd67:d6a7:d6f3::50";
        keys = {
          sshPub = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMJQhmbeDldaoqiRgYrYrtKY7l2eemsJyQBD9OT3UBM0";
          wgPub = "7hPavXcPF2zfFbimfyjI40BBM7vmwGdl5kA9DN1Y+28=";
        };
        roles = {
          postgres = true;
        };
      };
      brigid = {
        hostname = "brigid";
        ip.internal = "fd67:d6a7:d6f3::51";
        keys = {
          sshPub = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPVE5J272luQVFpnDgPPpi/37NLz1KuHBHK7yOOC5Zd8";
          wgPub = "TY8me/FEIRZBNctQ+l15cvxND/S4ALAz4OsaLshWvQ0=";
        };
        roles = {
          builder = true;
        };
      };
      # home-LAN DNS appliance (laptop). fleet member, but serves nothing to the
      # fleet - no directory.services entry, so no vhost on the edge.
      hestia = {
        hostname = "hestia";
        ip = {
          internal = "fd67:d6a7:d6f3::52";
          # same home router as ishtar: reuse ishtar's public IPs, distinct
          # forwarded port (router forwards :51285 -> hestia's LAN reservation).
          public = {
            v4 = "47.32.246.158";
            v6 = "2600:6c56:7008:200:94a2:3f0d:ccbb:f89e";
            port = 51285;
          };
        };
        keys = {
          sshPub = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILlSAa6LSj0rGcwjTx1z05uC7yKnoM1v/CkcaBL0h6wb";
          wgPub = "L3rihCr/61hoLxdRxXgThfvW2/SGXJUUjb5LhdY8KCA=";
        };
        roles = {
        };
      };
    };
    peers = {
      phone = {
        ip.internal = "fd67:d6a7:d6f3::100";
        keys.wgPub = "HqF57zMQiERxyZ4lG5A3uHJFddMr5kHabnP4cIlFXCI=";
      };
      tablet = {
        ip.internal = "fd67:d6a7:d6f3::150";
        keys.wgPub = "pLS7wnnThXR1wy8tQKHIfPeCxiSkB9r3+ijVOWJ9hHo=";
      };
    };
    services = {
      git = {
        backend = "minerva";
        port = 3030;
        public = true;
        module = "forgejo";
      };
      grafana = {
        backend = "minerva";
        port = 3000;
        module = "grafana";
      };
      notes = {
        backend = "minerva";
        port = 4567;
        module = "wiki-js";
      };
      vault = {
        backend = "minerva";
        port = 8222;
        module = "vaultwarden";
        extraConfig = "encode zstd gzip";
      };
      proxmox = {
        backend = "minerva";
        port = 8007; # minerva-side listener (8006 is proxmox itself)
        module = "proxmox-proxy";
        # no public = true -> edge caddy binds it to WG, VPN-only
      };
    };
  };
}
