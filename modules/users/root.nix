{ ... }: {
  flake.nixosModules.rootUser = { config, ... }: {
    home-manager.users.root = {
      home = {
        inherit (config.system) stateVersion;
        username = "root";
        homeDirectory = "/root";
        shell.enableShellIntegration = true;
      };
    };
  };
}
