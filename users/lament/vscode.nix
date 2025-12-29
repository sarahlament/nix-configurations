{
  config,
  lib,
  pkgs,
  ...
}: {
  programs = {
    vscode = {
      enable = true;
      package = pkgs.vscodium;

      profiles.default = {
        extensions = with pkgs.vscode-extensions; [
          jnoortheen.nix-ide
          eamodio.gitlens
        ];

        userSettings = {
          "workbench.startupEditor" = "none";
          "workbench.welcomePage.walkthroughs.openOnInstall" = false;
          "workbench.settings.editor" = "json";

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
          "nix.formatterPath" = "${pkgs.alejandra}/bin/alejandra";
          "nix.serverSettings" = {
            "nixd" = {
              "formatting" = {
                "command" = ["${pkgs.alejandra}/bin/alejandra"];
              };
              "options" = {
                "nixpkgs" = {
                  "expr" = "(builtins.getFlake \"/home/lament/.nix-conf\").nixosConfigurations.ishtar.pkgs";
                };
                "nixos" = {
                  "expr" = "(builtins.getFlake \"/home/lament/.nix-conf\").nixosConfigurations.ishtar.options";
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
          "editor.defaultFormatter" = "jnoortheen.nix-ide";

          "diffEditor.codeLens" = true;
          "diffEditor.experimental.showMoves" = true;
          "diffEditor.experimental.useTrueInlineView" = true;

          "workbench.iconTheme" = "charmed-icons";
          "workbench.panel.defaultLocation" = "right";

          "terminal.external.linuxExec" = "kitty";
          "terminal.integrated.defaultProfile.linux" = "zsh";

          "catppuccin-noctis-icons.hidesExplorerArrows" = false;
          "geminicodeassist.project" = "supple-shard-xm6t3";
        };
      };
    };
  };
}
