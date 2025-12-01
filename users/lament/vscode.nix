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
          anthropic.claude-code
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

          "gitlens.currentLine.enabled" = false;
          "gitlens.hovers.currentLine.over" = "line";
          "gitlens.ai.model" = "gitkraken";
          "claudeCode.preferredLocation" = "panel";
        };
      };
    };
  };
}
