{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.rootUser = {
    config,
    options,
    lib,
    pkgs,
    ...
  }: {
    home-manager.users.root = {
      home = {
        stateVersion = config.system.stateVersion;
        username = "root";
        homeDirectory = "/root";
        shell.enableShellIntegration = true;
      };
    };
  };
}
