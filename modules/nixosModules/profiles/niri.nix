{ inputs, ... }: {
  flake.nixosModules.niri =
    { config, pkgs, ... }:
    let
      niri-session = "${config.programs.niri.package}/bin/niri-session";
    in
    {
      imports = [ inputs.niri.nixosModules.niri ];

      # niri-flake wires the portals + polkit niri needs; we just turn it on.
      # NOTE: config is intentionally RAW for now - iterate ~/.config/niri and
      # ~/.config/noctalia live against their hot-reload (both survive reboots,
      # /home is a persistent subvol), then codify into HM once dialed in. So
      # deliberately no programs.niri.settings / noctalia HM module here yet -
      # just the binaries + the session/greeter plumbing to boot into it.
      programs.niri.enable = true;

      # niri-flake ships xdg-desktop-portal-gnome (screencast/screenshot) and a
      # portals.conf that names `gtk` as the FileChooser fallback - but never
      # pulls the gtk backend in, and gnome's FileChooser doesn't render outside
      # a gnome session. net result: file pickers (save/open/import) silently
      # no-op in every app, flatpak and native alike. add the gtk backend and
      # pin it as the FileChooser impl so dialogs actually show.
      xdg.portal = {
        extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
        config.niri."org.freedesktop.impl.portal.FileChooser" = "gtk";
      };
      # niri-unstable (git main): noctalia v5 themes niri via `include` +
      # `recent-windows` nodes that niri-stable 25.08 doesn't parse yet. cached in
      # niri.cachix.org same as stable.
      programs.niri.package = inputs.niri.packages.${pkgs.stdenv.hostPlatform.system}.niri-unstable;

      # greeter: greetd + tuigreet. lament autologins at boot (initial_session);
      # tuigreet is shown on logout / session switch. Drop initial_session to
      # always land on the tuigreet prompt instead of autologin.
      services.greetd = {
        enable = true;
        settings = {
          default_session.command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd ${niri-session}";
          initial_session = {
            command = niri-session;
            user = "lament";
          };
        };
      };

      hardware.graphics.enable = true;

      fonts = {
        enableDefaultPackages = true;
        enableGhostscriptFonts = true;
      };

      environment.systemPackages = [
        pkgs.xdg-utils
        pkgs.xwayland-satellite # rootless X for steam / X11 apps under niri
        inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default # noctalia-shell (raw-configured)
      ];
    };
}
