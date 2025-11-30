{
  config,
  inputs,
  ...
}: {
  imports = [
    inputs.disko.nixosModules.disko
    inputs.lanzaboote.nixosModules.lanzaboote
    inputs.aagl.nixosModules.default

    ./aagl.nix
    ./boot.nix
    ./disko.nix
    ./fastfetch.nix
    ./packages.nix
    ./stylix.nix
  ];
  sops.age.keyFile = "/persist/key.age";

  atelier.system.core.hostName = "LamentOS";
  atelier.hardware.graphics.vendor = "nvidia";
  atelier.hardware.efi.enable = true;
  atelier.system.theming.enable = true;
  atelier.system.theming.useDefaultTheme = false;
  atelier.users.sudoNoPassword = true;

  atelier.kits.desktop.enable = true;
  atelier.kits.desktop.autoLogin.user = "lament";
  atelier.kits.gaming.enable = true;
  atelier.kits.development.enable = true;
  atelier.kits.kde.enable = true;
  atelier.kits.virtualisation.enable = true;

  atelier.user.lament.extraGroups = [
    "video"
  ];

  services.fwupd.enable = true;
  security.rtkit.enable = true;

  services.udev.extraRules = ''
    KERNEL=="card*", SUBSYSTEM=="drm", GROUP="video", MODE="0660"
    KERNEL=="renderD*", SUBSYSTEM=="drm", GROUP="video", MODE="0660"
  '';

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
