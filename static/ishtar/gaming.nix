{ pkgs, ... }: {
  programs.gamescope.args = [
    "--prefer-output DP-1"
    "-W2560 -H1440 -r165"
  ];

  fileSystems."/persist/gamedir" = {
    device = "/dev/disk/by-label/GAMEDIR";
    fsType = "ext4";
  };

  environment.systemPackages = with pkgs; [
    xivlauncher
    vintagestory
  ];
}
