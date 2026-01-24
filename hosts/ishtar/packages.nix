{
  config,
  lib,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    dotnet-sdk_10 # .NET SDK
    lsfg-vk # Lossless Scaling frame generation (Vulkan)
    r2modman # Mod manager for various games
    #ryubing-canary # Switch emulator
    prismlauncher
    visualvm # java vm visualizer
    discord # Voice and text chat
    thunderbird # email client
    jetbrains.idea-oss # IntelliJ IDEA
    waydroid # android emulator
    waydroid-helper

    wineWowPackages.stagingFull
    winetricks
  ];
}
