{
  config,
  lib,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    # Core System Utilities
    curl # HTTP client
    glib # Low-level system library
    jq # JSON processor
    xdg-utils # XDG desktop integration
    unrar # RAR archive extraction
    gdu # Disk usage analyzer
  ];
}
