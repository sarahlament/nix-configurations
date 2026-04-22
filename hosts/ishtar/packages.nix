{
  config,
  lib,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    lsfg-vk # Lossless Scaling frame generation (Vulkan)
    r2modman # Mod manager for various games
    #ryubing-canary # Switch emulator
    prismlauncher
    discord # Voice and text chat
    thunderbird # email client
    waydroid # android emulator
    waydroid-helper
    libreoffice-fresh
    thunderbird
  ];
}
