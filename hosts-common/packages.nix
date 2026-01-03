{
  config,
  lib,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    attic-client # cachix alternative
    curl # HTTP client
    glib # Low-level system library
    jq # JSON processor
    xdg-utils # XDG desktop integration
    unrar # RAR archive extraction
    gdu # Disk usage analyzer
    wl-clipboard # Wayland clipboard utilities
    wl-clip-persist # Persistent clipboard for Wayland

    nom
    nvd
  ];
}
