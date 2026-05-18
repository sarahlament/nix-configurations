{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.ssh = {
    config,
    lib,
    pkgs,
    ...
  }: {
    # normally we would also define a jail here, but NixOS ships with one
    # for sshd by default, so we use it
    imports = [self.nixosModules.fail2ban];

    networking.firewall.allowedTCPPorts = [22];
    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
      };
    };
  };
}
