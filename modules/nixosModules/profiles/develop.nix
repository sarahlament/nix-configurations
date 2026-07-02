{ self, ... }: {
  flake.nixosModules.develop = { pkgs, ... }: {
    config = {
      programs.virt-manager.enable = true;
      virtualisation = {
        docker.enable = true;
        libvirtd = {
          enable = true;
          qemu.vhostUserPackages = with pkgs; [ virtiofsd ];
        };
        spiceUSBRedirection.enable = true;
      };
      home-manager.sharedModules = [ self.homeModules.virt-manager ];

      programs.direnv = {
        enable = true;
        silent = true;
        nix-direnv.enable = true;
      };

      environment.systemPackages = with pkgs; [
        nixfmt-tree # Nix formatter
        distrobox # seamlessly use other distros with docker
        jetbrains-toolbox # IDE manager
        nixd # Nix language server
        nodejs # JavaScript runtime
        python3 # Python interpreter
        rustup # Rust toolchain installer
        uv # Python package manager
        visualvm # java vm visualizer
      ];
    };
  };

  # normally, this would live in modules/homeModules but with how little it is (and it's necessity for virt (a dev concern)) it stays here
  flake.homeModules.virt-manager = { ... }: {
    dconf.settings = {
      "org/virt-manager/virt-manager/connections" = {
        autoconnect = [ "qemu:///system" ];
        uris = [ "qemu:///system" ];
      };
    };
    home.sessionPath = [
      "~/.local/share/JetBrains/Toolbox/scripts" # not vscode, but no real better place
    ];
  };
}
