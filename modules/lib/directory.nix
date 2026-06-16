{inputs, ...}: {
  flake.myLib.directory = {
    hosts = {
      athena = {
        hostname = "athena";
        tailip = "100.64.0.1";
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGkJt8Fdv4oR79C3wNB0IQBXD//OWu3sH0I1r5JYMaM3";
      };
      ishtar = {
        hostname = "ishtar";
        tailip = "100.64.0.2";
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA8zVl6CUXd4tEb1zpdbV1SMB7taFSg+3Y3QJksY9+vU";
      };
    };
  };
}
