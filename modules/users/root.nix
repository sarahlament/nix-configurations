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
    options.modules.root.stylix.enable = lib.mkEnableOption "Should root use stylix";
    # I want some shell things to work the same as they do for my user, so
    # root gets a home-manager definition to take advantage of sharedModules
    config = {
      home-manager.users.root = {
        home = {
          stateVersion = config.system.stateVersion;
          username = "root";
          homeDirectory = "/root";
          shell.enableShellIntegration = true;
        };
        stylix.enable = config.modules.root.stylix.enable;
      };
    };
  };
}
