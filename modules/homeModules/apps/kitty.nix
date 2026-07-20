{ ... }: {
  flake.homeModules.kitty = { ... }: {
    programs = {
      kitty = {
        enable = true;

        shellIntegration.enableZshIntegration = true;
        settings = {
          font_family = "JetBrains Mono Nerd Font";
          font_size = 13;
          background_opacity = "0.85";
          initial_window_width = 1366;
          initial_window_height = 768;
          remember_window_size = "no";
          enable_audio_bell = false;
          dynamic_background_opacity = true;
          cursor_blink_interval = 0.5;
          cursor_stop_blinking_after = 5;
          scrollback_lines = 5000;
          window_padding_width = 5;
          cursor_trail = 5;
          cursor_trail_decay = "0.2 0.6";
          scrollbar = "scrolled-and-hovered";
          scrollback_indicator_opacity = 0.75;
          mouse_hide_wait = 5;
          show_hyperlink_targets = true;
          underline_hyperlinks = "always";
        };
      };
    };
  };
}
