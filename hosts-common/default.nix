{
  config,
  inputs,
  ...
}: {
  imports = [
    inputs.sops-nix.nixosModules.sops

    ./boot.nix # Shared boot options
    ./nixconf.nix # 'nix' configuration
    ./packages.nix # shared packages
    ./sops.nix # sops-nix information
  ];

  atelier.system.core.enable = true;
  atelier.system.core.timeZone = "America/Chicago";
  atelier.shell.modernTools.useRustSudo = true;
}
