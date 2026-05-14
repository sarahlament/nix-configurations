{inputs, ...}: {
  flake.nixosModules.develop = {
    config,
    lib,
    pkgs,
    ...
  }: {
    programs.virt-manager.enable = true;
    virtualisation = {
      docker.enable = true;
      libvirtd = {
        enable = true;
        qemu.vhostUserPackages = with pkgs; [virtiofsd];
      };
      spiceUSBRedirection.enable = true;
    };

    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    environment.systemPackages = with pkgs; [
      nixd # Nix language server
      alejandra # Nix formatter
      nodejs # JavaScript runtime
      uv # Python package manager
      python3 # Python interpreter
      rustup # Rust toolchain installer
      visualvm # java vm visualizer
      jetbrains-toolbox # IDE manager
    ];
  };

  flake.homeModules.develop = {
    config,
    lib,
    pkgs,
    ...
  }: {
    dconf.settings = {
      "org/virt-manager/virt-manager/connections" = {
        autoconnect = ["qemu:///system"];
        uris = ["qemu:///system"];
      };
    };
    home.sessionPath = [
      "~/.local/share/JetBrains/Toolbox/scripts" # not vscode, but no real better place
    ];
  };
}
