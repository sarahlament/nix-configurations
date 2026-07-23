{ ... }: {
  flake.myLib.directory = {
    hosts = {
      athena = {
        hostname = "athena";
        stateVersion = "26.05";
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
        stateVersion = "26.05";
        channel = "nixpkgs";
        ip.internal = "fd67:d6a7:d6f3::2";
        keys = {
          sshPub = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA8zVl6CUXd4tEb1zpdbV1SMB7taFSg+3Y3QJksY9+vU";
          wgPub = "2/eP72pROfrKRSrxPKeoroVtq9K+jvz1T4Gl4tPg03c=";
        };
        roles = {
        };
      };
      minerva = {
        hostname = "minerva";
        stateVersion = "26.11";
        site = "fate";
        ip = {
          internal = "fd67:d6a7:d6f3::50";
          site = "192.168.4.132";
        };
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
        stateVersion = "26.11";
        channel = "nixpkgs";
        site = "fate";
        ip = {
          internal = "fd67:d6a7:d6f3::51";
          site = "192.168.4.7";
        };
        keys = {
          sshPub = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPVE5J272luQVFpnDgPPpi/37NLz1KuHBHK7yOOC5Zd8";
          wgPub = "TY8me/FEIRZBNctQ+l15cvxND/S4ALAz4OsaLshWvQ0=";
        };
        roles = {
          builder = true;
        };
      };
      # home-LAN DNS appliance (laptop). PARKED 2026-07-23: powered off (slow
      # WiFi), pulled from the fleet until it's back in actual use. grafana's
      # blackbox probes rode this box, so they're commented out too - uncomment
      # both to restore.
      /*
        hestia = {
          hostname = "hestia";
          stateVersion = "26.11";
          ip.internal = "fd67:d6a7:d6f3::52";
          keys = {
            sshPub = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILlSAa6LSj0rGcwjTx1z05uC7yKnoM1v/CkcaBL0h6wb";
            wgPub = "L3rihCr/61hoLxdRxXgThfvW2/SGXJUUjb5LhdY8KCA=";
          };
          roles = {
          };
        };
      */
      # identity box (LUKS+TPM testbed for ishtar). role-less for now: the
      # kerberos/directory stack it will carry doesn't exist yet.
      verdandi = {
        hostname = "verdandi";
        stateVersion = "26.11";
        site = "fate";
        ip = {
          internal = "fd67:d6a7:d6f3::53";
          site = "192.168.4.73";
        };
        keys = {
          sshPub = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKRTZ7gUJe57AjlNUjejA7ajfhng46wmC0rlki7LAE1N";
          wgPub = "NSYBMZZmakM3TTdFV/avnAyJowEUEgjOu/1lyyGyBDY=";
        };
        roles = {
          identity = true;
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
