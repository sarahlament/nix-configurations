{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.lament = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) mkEnableOption optionals;
    cfg = config.modules.lament;
  in {
    imports = [inputs.home-manager.nixosModules.home-manager];
    options.modules.lament = {
      desktop.enable = mkEnableOption "Enable desktop config";
    };

    config = {
      sops.secrets.lamentUserPass.neededForUsers = true;
      nix.settings.trusted-users = ["lament"];
      users.users.lament = {
        description = "Sarah Lament";
        hashedPasswordFile = config.sops.secrets.lamentUserPass.path;
        isNormalUser = true;
        openssh.authorizedKeys.keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBWSe/rbjk1/7meA90ZAg1hR3TcbKUgjB4GEl18SF1bZ"]; # personal key
        extraGroups = [
          "wheel"
          "systemd-journal"
          "networkmanager"
          "plugdev"
          "video"
          "docker"
          "libvirtd"
          "gamemode"
        ];
      };
      services.displayManager.autoLogin = {
        enable = true;
        user = "lament";
      };

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "hmb";
        users.lament = {
          imports = with self.homeModules;
            [
              btop
              git
              hyfetch
              kitty
              nixvim
              shell
              zsh
            ]
            ++ optionals (cfg.desktop.enable) [
              develop
              vscode
              (inputs.import-tree (self + "/static/lament/desktop"))
            ]; # ++ optionals (cfg.server.enable)[]; if needed/wanted

          home = {
            stateVersion = config.system.stateVersion;
            username = "lament";
            homeDirectory = "/home/lament";
            shell.enableShellIntegration = true;
          };
        };
      };
    };
  };
}
