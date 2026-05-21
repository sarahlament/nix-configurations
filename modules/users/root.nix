{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.rootUser = {
    config,
    lib,
    pkgs,
    ...
  }: {
    # I want some shell things to work the same as they do for my user, so
    # root gets a home-manager definition to take advantage of sharedModules
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
