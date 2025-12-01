{
  config,
  lib,
  pkgs,
  ...
}: {
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
              outputColor = "38;2;136;192;208"; # blue
            }
            {
              type = "os";
              key = "│ OS";
              keyColor = "38;2;136;192;208";
            }
            {
              type = "host";
              key = "│ Host";
              keyColor = "38;2;136;192;208";
            }
            {
              type = "kernel";
              key = "│ Kernel";
              keyColor = "38;2;136;192;208";
            }
            {
              type = "uptime";
              key = "│ Uptime";
              keyColor = "38;2;136;192;208";
            }
            {
              type = "packages";
              key = "│ Packages";
              keyColor = "38;2;136;192;208";
            }
            {
              type = "shell";
              key = "│ Shell";
              keyColor = "38;2;136;192;208";
            }
            {
              type = "custom";
              format = "╰──────────────────────────────────────────────────────────────╯";
              outputColor = "38;2;136;192;208";
            }
            {
              type = "custom";
              format = "╭─ Hardware ───────────────────────────────────────────────────╮";
              outputColor = "38;2;163;190;140"; # green
            }
            {
              type = "cpu";
              key = "│ CPU";
              keyColor = "38;2;163;190;140";
            }
            {
              type = "memory";
              key = "│ Memory";
              keyColor = "38;2;163;190;140";
            }
            {
              type = "swap";
              key = "│ Swap";
              keyColor = "38;2;163;190;140";
            }
            {
              type = "disk";
              key = "│ Disk";
              keyColor = "38;2;163;190;140";
            }
            {
              type = "custom";
              format = "╰──────────────────────────────────────────────────────────────╯";
              outputColor = "38;2;163;190;140";
            }
            {
              type = "custom";
              format = "╭─ Network ────────────────────────────────────────────────────╮";
              outputColor = "38;2;180;142;173"; # magenta/purple
            }
            {
              type = "title";
              fqdn = true;
              key = "│ User";
              keyColor = "38;2;180;142;173";
              color = {
                user = "bright_white";
                at = "bright_white";
                host = "bright_white";
              };
            }
            {
              type = "localip";
              key = "│ Local IP";
              keyColor = "38;2;180;142;173";
            }
            {
              type = "publicip";
              key = "│ Public IP";
              keyColor = "38;2;180;142;173";
              format = "{ip}";
              timeout = 3000;
            }
            {
              type = "command";
              key = "│ Public IPv6";
              keyColor = "38;2;180;142;173";
              text = "curl -s --max-time 3 https://ipv6.icanhazip.com 2>/dev/null || echo 'N/A'";
            }
            {
              type = "locale";
              key = "│ Locale";
              keyColor = "38;2;180;142;173";
            }
            {
              type = "custom";
              format = "╰──────────────────────────────────────────────────────────────╯";
              outputColor = "38;2;180;142;173";
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
