{
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

    home-manager.sharedModules = [
      {
        dconf.settings = {
          "org/virt-manager/virt-manager/connections" = {
            autoconnect = ["qemu:///system"];
            uris = ["qemu:///system"];
          };
        };
      }
    ];

    environment.systemPackages = with pkgs; [
      nixd # Nix language server
      alejandra # Nix formatter
      nodejs # JavaScript runtime
      uv # Python package manager
      python3 # Python interpreter
      rustup # Rust toolchain installer
    ];
}
