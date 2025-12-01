{
  config,
  lib,
  pkgs,
  ...
}: {
  programs = {
    claude-code.enable = true;
    nix-index.enable = true;
    btop = {
      enable = true;
      settings = {
        # Performance
        update_ms = 2000; # 2 second refresh (less CPU usage)

        # Display preferences
        show_uptime = true;
        proc_tree = true; # Show process tree like htop
        proc_sorting = "cpu lazy"; # Sort by CPU usage
        proc_reversed = false;

        # CPU display
        cpu_graph_upper = "total";
        cpu_graph_lower = "total";

        # Memory display
        mem_graph_upper = "used";
        mem_graph_lower = "available";

        # Hide network/IO (you can toggle on manually if needed)
        show_io_stat = false;
        show_disks = false;

        # Interface
        vim_keys = false; # Use normal arrow key navigation
        show_battery = true;
        clock_format = "%H:%M";
      };
    };
  };
}
