{
  config,
  lib,
  pkgs,
  ...
}: let
  # Helper function to convert hex color to RGB format for fastfetch (38;2;R;G;B)
  hexToRgb = hex: let
    r = builtins.substring 0 2 hex;
    g = builtins.substring 2 2 hex;
    b = builtins.substring 4 2 hex;
    toDecimal = h: (builtins.fromTOML "v=0x${h}").v;
  in "38;2;${toString (toDecimal r)};${toString (toDecimal g)};${toString (toDecimal b)}";

  colors = config.lib.stylix.colors;
  systemColor = hexToRgb colors.base0D; # blue - system information
  desktopColor = hexToRgb colors.base09; # orange - desktop/UI context
  hardwareColor = hexToRgb colors.base0B; # green - hardware/resources
  infoColor = hexToRgb colors.base0E; # magenta/purple - user info
in {
  home-manager.sharedModules = [
    {
      programs.fastfetch = {
        enable = true;
        settings = {
          "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";
          logo = {
            type = "auto";
          };
          display = {
            separator = "  ";
          };
          modules = [
            "break"
            {
              type = "custom";
              format = "╭─ System ─────────────────────────────────────────────────────╮";
              outputColor = systemColor;
            }
            {
              type = "os";
              key = "│ OS";
              keyColor = systemColor;
            }
            {
              type = "host";
              key = "│ Host";
              keyColor = systemColor;
            }
            {
              type = "kernel";
              key = "│ Kernel";
              keyColor = systemColor;
            }
            {
              type = "uptime";
              key = "│ Uptime";
              keyColor = systemColor;
            }
            {
              type = "packages";
              key = "│ Packages";
              keyColor = systemColor;
            }
            {
              type = "shell";
              key = "│ Shell";
              keyColor = systemColor;
            }
            {
              type = "terminal";
              key = "│ Terminal";
              keyColor = systemColor;
            }
            {
              type = "custom";
              format = "╰──────────────────────────────────────────────────────────────╯";
              outputColor = systemColor;
            }
            {
              type = "custom";
              format = "╭─ Desktop ────────────────────────────────────────────────────╮";
              outputColor = desktopColor;
            }
            {
              type = "wm";
              key = "│ WM";
              keyColor = desktopColor;
            }
            {
              type = "wmtheme";
              key = "│ WM Theme";
              keyColor = desktopColor;
            }
            {
              type = "theme";
              key = "│ Theme";
              keyColor = desktopColor;
            }
            {
              type = "cursor";
              key = "│ Cursor";
              keyColor = desktopColor;
            }
            {
              type = "icons";
              key = "│ Icons";
              keyColor = desktopColor;
            }
            {
              type = "font";
              key = "│ Font";
              keyColor = desktopColor;
            }
            {
              type = "terminalfont";
              key = "│ Term Font";
              keyColor = desktopColor;
            }
            {
              type = "custom";
              format = "╰──────────────────────────────────────────────────────────────╯";
              outputColor = desktopColor;
            }
            {
              type = "custom";
              format = "╭─ Hardware ───────────────────────────────────────────────────╮";
              outputColor = hardwareColor;
            }
            {
              type = "cpu";
              key = "│ CPU";
              keyColor = hardwareColor;
            }
            {
              type = "gpu";
              key = "│ GPU";
              keyColor = hardwareColor;
            }
            {
              type = "sound";
              key = "│ Sound";
              keyColor = hardwareColor;
            }
            {
              type = "memory";
              key = "│ Memory";
              keyColor = hardwareColor;
            }
            {
              type = "swap";
              key = "│ Swap";
              keyColor = hardwareColor;
            }
            {
              type = "disk";
              key = "│ Disk";
              keyColor = hardwareColor;
            }
            {
              type = "custom";
              format = "╰──────────────────────────────────────────────────────────────╯";
              outputColor = hardwareColor;
            }
            {
              type = "custom";
              format = "╭─ Info ───────────────────────────────────────────────────────╮";
              outputColor = infoColor;
            }
            {
              type = "title";
              fqdn = true;
              key = "│ User";
              keyColor = infoColor;
              color = {
                user = "bright_white";
                at = "bright_white";
                host = "bright_white";
              };
            }
            {
              type = "localip";
              key = "│ Local IP";
              keyColor = infoColor;
            }
            {
              type = "publicip";
              key = "│ Public IP";
              keyColor = infoColor;
              format = "{ip}";
              timeout = 3000;
            }
            {
              type = "command";
              key = "│ Public IPv6";
              keyColor = infoColor;
              text = "curl -s --max-time 3 https://ipv6.icanhazip.com 2>/dev/null || echo 'N/A'";
            }
            {
              type = "locale";
              key = "│ Locale";
              keyColor = infoColor;
            }
            {
              type = "weather";
              key = "│ Weather";
              keyColor = infoColor;
              location = "Fort Worth, Texas";
              timeout = 3000;
            }
            {
              type = "custom";
              format = "╰──────────────────────────────────────────────────────────────╯";
              outputColor = infoColor;
            }
            "break"
            {
              type = "colors";
              symbol = "circle";
            }
            "break"
          ];
        };
      };
    }
  ];
}
