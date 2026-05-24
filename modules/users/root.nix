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
    options.modules.root.stylixDisabler = lib.mkEnableOption "Disable stylix things on desktop";
    # I want some shell things to work the same as they do for my user, so
    # root gets a home-manager definition to take advantage of sharedModules
    config = {
      home-manager.users.root =
        {
          home = {
            stateVersion = config.system.stateVersion;
            username = "root";
            homeDirectory = "/root";
            shell.enableShellIntegration = true;
          };
        }
        // lib.optionalAttrs config.modules.root.stylixDisabler {
          stylix.enable = false;
        };
    };
  };
}
