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
          resolver = true;
          mailserver = true;
          knot = true;
          wgHub = true;
          impermanent = true;
        };
      };
      ishtar = {
        hostname = "ishtar";
        ip.internal = "fd67:d6a7:d6f3::2";
        keys = {
          sshPub = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA8zVl6CUXd4tEb1zpdbV1SMB7taFSg+3Y3QJksY9+vU";
          wgPub = "2/eP72pROfrKRSrxPKeoroVtq9K+jvz1T4Gl4tPg03c=";
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
          impermanent = true;
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
        module = "gollum";
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
