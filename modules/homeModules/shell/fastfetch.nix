{inputs, ...}: {
  flake.homeModules.fastfetch = {
    config,
    lib,
    pkgs,
    ...
  }: {
    programs.fastfetch = let
      treeColor = "38;2;184;196;255";
    in {
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
  };
}
