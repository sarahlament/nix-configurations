{
  config,
  inputs,
  ...
}: {
  imports = [
    inputs.disko.nixosModules.disko
    inputs.lanzaboote.nixosModules.lanzaboote
    inputs.stylix.nixosModules.stylix
    inputs.aagl.nixosModules.default

    ./aagl.nix
    ./boot.nix
    ./disko.nix
    ./fastfetch.nix
    ./nvidia.nix
    ./packages.nix
    ./posh.nix
    ./stylix.nix
  ];
  sops.age.keyFile = "/persist/key.age";

  networking.hostName = "LamentOS";
  security.sudo-rs.wheelNeedsPassword = false;

  atelier.kits.desktop.enable = true;
  atelier.kits.desktop.autoLogin.user = "lament";
  atelier.kits.gaming.enable = true;
  atelier.kits.development.enable = true;
  atelier.kits.kde.enable = true;
  atelier.kits.virtualisation.enable = true;

  services.fwupd.enable = true;
  security.rtkit.enable = true;

  programs.firefox.enable = true;
  programs.gamescope = {
    args = [
      "--rt"
      "--fullscreen"
      "--hdr-enabled"
      "--hdr-itm-enable"
      "--prefer-output DP-1"
      "-W2560 -H1440 -r165"
    ];
    env = {
      DXVK_HDR = "1";
      ENABLE_GAMESCOPE_WSI = "1";
    };
  };

  fileSystems."/persist/gamedir" = {
    device = "/dev/disk/by-label/GAMEDIR";
    fsType = "ext4";
  };
}
