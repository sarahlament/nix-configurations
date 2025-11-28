{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.atelier.kits.development;
  graphics = config.atelier.hardware.graphics;
in {
  options.atelier.kits.development = {
    enable = mkEnableOption "development kit";
  };

  config = mkIf cfg.enable {
    virtualisation.docker.enable = true;
    hardware.nvidia-container-toolkit.enable = mkIf (graphics.vendor == "nvidia") true;

    environment.systemPackages = with pkgs; [
      nixd # Nix language server
      alejandra # Nix formatter
      nodejs # JavaScript runtime
      uv # Python package manager
      python3 # Python interpreter
      rustup # Rust toolchain installer
    ];
  };
}
