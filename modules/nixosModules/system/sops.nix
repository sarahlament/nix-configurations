{ inputs, ... }: {
  flake.nixosModules.sops = { ... }: {
    imports = [ inputs.sops.nixosModules.sops ];
    sops.age.keyFile = "/persist/key.age";
    sops.defaultSopsFormat = "yaml";
  };
}
