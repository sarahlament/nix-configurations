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
        inputs.noctalia.packages.${pkgs.system}.default # noctalia-shell (raw-configured)
      ];
    };
}
