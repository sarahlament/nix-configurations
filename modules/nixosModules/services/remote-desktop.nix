{...}: {
  # Tailnet-only remote desktop (RDP) for headless GUI testing.
  #
  # Relies on the `networking` module trusting `tailscale0`: with the firewall
  # left closed (openFirewall = false), xrdp's port 3389 is reachable over the
  # tailnet but blocked on every other interface. No public exposure.
  #
  # NOTE: xrdp starts its own Xorg-backed Plasma session (startplasma-x11)
  # rather than mirroring the live Wayland session on the physical display.
  # That's intentional: it's far more reliable for remote use, and apps run
  # under X11 which avoids the Wayland/dmabuf WebKitGTK crashes.
  flake.nixosModules.remoteDesktop = {pkgs, ...}: {
    services.xrdp = {
      enable = true;
      defaultWindowManager = "${pkgs.kdePackages.plasma-workspace}/bin/startplasma-x11";
      openFirewall = false;
    };
  };
}
