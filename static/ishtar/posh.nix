{
  config,
  lib,
  pkgs,
  ...
}: let
  stylixhash = config.lib.stylix.colors.withHashtag;
in {
  home-manager.sharedModules = [
    {
      programs.oh-my-posh = {
        enable = true;
        settings = {
          "$schema" = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json";
          palette = {
            active_focus = stylixhash.base0E; # magenta/purple - active elements
            system_info = stylixhash.base0E; # magenta/purple - system info
            time_display = stylixhash.base0C; # cyan - time/duration
            dev_context = stylixhash.base09; # orange - git/dev context
            status_success = stylixhash.base0B; # green - success states
            status_warning = stylixhash.base0A; # yellow - warnings
            status_error = stylixhash.base08; # red - errors
          };
          upgrade = {
            source = "cdn";
            interval = "168h";
            auto = false;
            notice = false;
          };
          transient_prompt = {
            foreground = "p:active_focus";
            template = "❯ ";
          };
          blocks = [
            {
              type = "prompt";
              alignment = "left";
              segments = [
                {
                  template = "{{.Icon}} ";
                  foreground = "p:system_info";
                  type = "os";
                  style = "plain";
                }
                {
                  template = "{{ .UserName }}@{{ .HostName }} ";
                  foreground = "p:active_focus";
                  type = "session";
                  style = "plain";
                }
                {
                  properties = {
                    home_icon = "~";
                    style = "full";
                  };
                  template = "{{ .Path }} ";
                  foreground = "p:active_focus";
                  type = "path";
                  style = "plain";
                }
                {
                  properties = {
                    fetch_status = true;
                    fetch_upstream_icon = true;
                  };
                  template = "{{ .HEAD }}{{if .BranchStatus }} {{ .BranchStatus }}{{ end }}{{ if .Staging.Changed }} <p:status_success> {{ .Staging.String }}</p:status_success>{{ end }}{{ if and (.Working.Changed) (.Staging.Changed) }} |{{ end }}{{ if .Working.Changed }} <p:status_warning> {{ .Working.String }}</p:status_warning>{{ end }} ";
                  foreground = "p:dev_context";
                  type = "git";
                  style = "plain";
                }
              ];
              newline = true;
            }
            {
              type = "prompt";
              alignment = "left";
              segments = [
                {
                  type = "python";
                  style = "plain";
                  foreground = "p:dev_context";
                  template = " {{ .Venv }} ";
                }
                {
                  type = "node";
                  style = "plain";
                  foreground = "p:dev_context";
                  template = " {{ .Major }}.{{ .Minor }} ";
                }
                {
                  type = "docker";
                  style = "plain";
                  foreground = "p:dev_context";
                  template = " {{ .Context }} ";
                }
                {
                  type = "go";
                  style = "plain";
                  foreground = "p:dev_context";
                  template = " {{ .Major }}.{{ .Minor }} ";
                }
                {
                  type = "rust";
                  style = "plain";
                  foreground = "p:dev_context";
                  template = " {{ .Major }}.{{ .Minor }} ";
                }
              ];
              newline = true;
            }
            {
              type = "prompt";
              alignment = "right";

              segments = [
                {
                  type = "sysinfo";
                  style = "plain";
                  foreground = "p:system_info";
                  template = "󰘚 {{ round .PhysicalPercentUsed .Precision }}% ";
                  properties = {
                    precision = 1;
                  };
                }
                {
                  type = "time";
                  style = "plain";
                  foreground = "p:time_display";
                  template = "󰅐 {{ .CurrentDate | date .Format }}";
                  properties = {
                    time_format = "15:04";
                  };
                }
              ];
            }
            {
              type = "prompt";
              alignment = "left";
              segments = [
                {
                  template = "❯ ";
                  foreground = "p:active_focus";
                  type = "text";
                  style = "plain";
                }
              ];
            }
            {
              type = "rprompt";
              segments = [
                {
                  type = "executiontime";
                  style = "plain";
                  foreground = "p:time_display";
                  template = "{{ .FormattedMs }}";
                  properties = {
                    style = "roundrock";
                    threshold = 2000;
                  };
                }
                {
                  type = "status";
                  style = "plain";
                  foreground = "p:status_error";
                  template = " ✘ {{ .Code }}";
                  properties = {
                    always_enabled = false;
                  };
                }
              ];
            }
          ];
          version = 3;
          final_space = true;
        };
      };
    }
  ];
}
