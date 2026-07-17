{ ... }: {
  flake.homeModules.vscode = { pkgs, ... }: {
    programs = {
      vscodium = {
        enable = true;

        profiles.default = {
          extensions = with pkgs.vscode-extensions; [
            jnoortheen.nix-ide
            eamodio.gitlens
            catppuccin.catppuccin-vsc-icons
          ];

          userSettings = {
            "window.zoomLevel" = 1;
            "workbench.startupEditor" = "none";
            "workbench.welcomePage.walkthroughs.openOnInstall" = false;
            "workbench.settings.editor" = "json";
            "workbench.iconTheme" = "catppuccin noctis icons";

            "update.mode" = "none";
            "extensions.ignoreRecommendations" = true;
            "extensions.autoUpdate" = false;
            "extensions.autoCheckUpdates" = false;

            "nix.enableLanguageServer" = true;
            "nix.hiddenLanguageServerErrors" = [
              "textDocument/definition"
              "textDocument/documentSymbol"
              "textDocument/formatting"
            ];
            "nix.serverPath" = "${pkgs.nixd}/bin/nixd";
            "nix.formatterPath" = "${pkgs.nixfmt}/bin/nixfmt";
            "nix.serverSettings" = {
              "nixd" = {
                "formatting" = {
                  "command" = [ "${pkgs.nixfmt}/bin/nixfmt" ];
                };
                "nixpkgs" = {
                  "expr" = "(builtins.getFlake \"/home/lament/Projects/pantheon\").nixosConfigurations.ishtar.pkgs";
                };
                "options" = {
                  "nixos" = {
                    "expr" =
                      "(builtins.getFlake \"/home/lament/Projects/pantheon\").nixosConfigurations.ishtar.options";
                  };
                  "mailserver" = {
                    "expr" =
                      "{ mailserver = (builtins.getFlake \"/home/lament/Projects/pantheon\").nixosConfigurations.athena.options.mailserver; }";
                  };
                  "home-manager" = {
                    "expr" =
                      "(builtins.getFlake \"/home/lament/Projects/pantheon\").nixosConfigurations.ishtar.options.home-manager.users.type.getSubOptions []";
                  };
                };
              };
            };

            "editor.formatOnSave" = true;
            "files.autoSave" = "afterDelay";
            "files.autoSaveDelay" = 2000;
            "editor.codeActionsOnSave" = {
              "source.organizeImports" = "explicit";
            };
            "editor.bracketPairColorization.enabled" = true;
            "editor.guides.bracketPairs" = "active";
            "editor.wordWrap" = "wordWrapColumn";
            "editor.wordWrapColumn" = 100;

            "explorer.confirmDragAndDrop" = false;
            "explorer.confirmDelete" = false;

            "claudeCode.preferredLocation" = "panel";
            "claudeCode.disableLoginPrompt" = true;

            "editor.aiStats.enabled" = true;
            "editor.autoIndentOnPaste" = true;
            "editor.codeActions.triggerOnFocusChange" = true;
            "editor.scrollbar.horizontal" = "hidden";
            "editor.unfoldOnClickAfterEndOfLine" = true;
            "editor.formatOnPaste" = true;
            "[nix]" = {
              "editor.defaultFormatter" = "jnoortheen.nix-ide";
            };

            "diffEditor.codeLens" = true;
            "diffEditor.experimental.showMoves" = true;
            "diffEditor.experimental.useTrueInlineView" = true;

            "workbench.panel.defaultLocation" = "right";

            "terminal.external.linuxExec" = "kitty";
            "terminal.integrated.defaultProfile.linux" = "zsh";

            "catppuccin-noctis-icons.hidesExplorerArrows" = false;
            "geminicodeassist.project" = "supple-shard-xm6t3";
            "claudeCode.selectedModel" = "opus";

            "mermaidLivePreview.useVSCodeTheme" = false;
            "mermaidLivePreview.theme" = "dark";
            "markdown-preview-enhanced.previewTheme" = "vscode.css";
          };
        };
      };
    };
  };
}
