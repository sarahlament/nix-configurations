{ ... }: {
  flake.myLib.directory = {
    hosts = {
      athena = {
        hostname = "athena";
        keys = {
          sshPub = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGkJt8Fdv4oR79C3wNB0IQBXD//OWu3sH0I1r5JYMaM3";
          wgPub = "3tPScod8UQO9f4KGXRGQDOSh30XEVeq/pOjkjBQ/LEM=";
        };
        ip.internal = "fd67:d6a7:d6f3::1";
        ip.public = {
          v4 = "104.200.16.195";
          v6 = "2600:3c00::2000:31ff:fe65:8d63";
        };
        roles = {
          resolver = true;
          mailserver = true;
          monitor = true;
          knot = true;
          wgHub = true;
        };
      };
      ishtar = {
        hostname = "ishtar";
        keys = {
          sshPub = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA8zVl6CUXd4tEb1zpdbV1SMB7taFSg+3Y3QJksY9+vU";
          wgPub = "2/eP72pROfrKRSrxPKeoroVtq9K+jvz1T4Gl4tPg03c=";
        };
        ip.internal = "fd67:d6a7:d6f3::2";
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
      public = [ "git" ];
      private.athena = [
        "grafana"
        "notes"
        "vault"
      ];
    };
  };
}
