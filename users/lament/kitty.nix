{
  config,
  lib,
  pkgs,
  ...
}: {
  programs = {
    kitty = {
      enable = true;

      shellIntegration.enableZshIntegration = true;
      settings = {
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
}
