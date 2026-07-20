{ pkgs, ... }:
{
  # fonts formerly owned by stylix (dropped with the NNN switch). noctalia's
  # matugen drives colors now; these are the plain font-family defaults stylix
  # used to set, ported as-is so nothing shifts. cursor lives in HM
  # (users/lament.nix) since it's a per-user/wayland concern.
  fonts = {
    packages = [
      pkgs.nerd-fonts.jetbrains-mono
      pkgs.fira
      pkgs.crimson
    ];
    fontconfig.defaultFonts = {
      monospace = [ "JetBrains Mono Nerd Font" ];
      sansSerif = [ "Fira Sans" ];
      serif = [ "Crimson Pro" ];
    };
  };
}
