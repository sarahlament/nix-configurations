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
  treeColor = hexToRgb colors.base0D; # blue - tree characters and keys
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
            {
              type = "title";
              fqdn = true;
              color = {
                user = "bright_white";
                at = "bright_white";
                host = "bright_white";
              };
            }
            {
              type = "os";
              key = "├─ OS";
              keyColor = treeColor;
            }
            {
              type = "kernel";
              key = "├─ Kernel";
              keyColor = treeColor;
            }
            {
              type = "uptime";
              key = "├─ Uptime";
              keyColor = treeColor;
            }
            {
              type = "localip";
              key = "├─ Local IP";
              keyColor = treeColor;
            }
            {
              type = "cpu";
              key = "├─ CPU";
              keyColor = treeColor;
            }
            {
              type = "cpuusage";
              key = "│  └─ Usage";
              keyColor = treeColor;
            }
            {
              type = "memory";
              key = "├─ Memory";
              keyColor = treeColor;
            }
            {
              type = "swap";
              key = "│  ├─ Swap";
              keyColor = treeColor;
            }
            {
              type = "loadavg";
              key = "│  └─ Load Avg";
              keyColor = treeColor;
            }
            {
              type = "disk";
              key = "├─ Disk";
              keyColor = treeColor;
            }
            {
              type = "packages";
              key = "└─ Packages";
              keyColor = treeColor;
            }
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
