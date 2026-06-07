{inputs, ...}: {
  flake.nixosModules.nvf = {
    config,
    pkgs,
    lib,
    ...
  }: {
    imports = [inputs.nvf.nixosModules.nvf];
    programs.nvf = {
      enable = true;
      defaultEditor = true;

      settings.vim = {
        vimAlias = true;

        options = {
          tabstop = 2;
          expandtab = false;
          shiftwidth = 2;
          number = true;
          relativenumber = true;
          scrolloff = 4;
          mouse = "a";
        };

        globals.mapleader = " ";

        keymaps = [
          # Telescope: File and text searching
          {
            key = "<leader>ff";
            action = "<cmd>Telescope find_files<cr>";
            mode = "n";
            desc = "Find Files";
          }
          {
            key = "<leader>fg";
            action = "<cmd>Telescope live_grep<cr>";
            mode = "n";
            desc = "Live Grep";
          }
          {
            key = "<leader>fb";
            action = "<cmd>Telescope buffers<cr>";
            mode = "n";
            desc = "Find Buffers";
          }
          {
            key = "<leader>fh";
            action = "<cmd>Telescope help_tags<cr>";
            mode = "n";
            desc = "Help Tags";
          }

          # Conform: Format code
          {
            key = "<leader><Tab>";
            action = "<cmd>ConformFormat<cr>";
            mode = ["n" "v"];
            desc = "Format code";
          }

          # Neo-tree: File explorer
          {
            key = "<leader>e";
            action = "<cmd>Neotree toggle<cr>";
            mode = "n";
            desc = "Toggle File Explorer";
          }

          # Oil.nvim: Edit filesystem
          {
            key = "-";
            action = "<cmd>Oil<cr>";
            mode = "n";
            desc = "Open parent directory";
          }
        ];

        # Which-key: Displays a popup of possible keybindings
        binds.whichKey.enable = true;

        # Noice: A more modern UI for messages and commands
        ui.noice.enable = true;

        visuals = {
          # Indent-blankline: Adds indentation guides
          indent-blankline.enable = true;

          # Web-devicons: Adds file type icons
          nvim-web-devicons.enable = true;
        };

        # Bufferline: VS Code-style tabs
        tabline.nvimBufferline.enable = true;

        lsp = {
          enable = true;
          formatOnSave = true;

          servers = {
            nil = {
              enable = true;
              settings = {
                nil = {
                  formatting.command = ["alejandra"];
                  nix.flake = {
                    autoArchive = true;
                    nixpkgsInputName = "nixos-unstable";
                  };
                };
              };
            };
          };

          presets = {
            taplo.enable = true;
            vscode-json-language-server.enable = true;
            bash-language-server.enable = true;
            yaml-language-server.enable = true;
            marksman.enable = true;
          };
        };

        # Treesitter: Better syntax highlighting and code parsing
        treesitter.enable = true;

        # Conform: A powerful and fast code formatter
        formatter.conform-nvim = {
          enable = false;
          setupOpts = {
            format_on_save = {
              lsp_format = "fallback";
              timeout_ms = 500;
            };
            formatters_by_ft = {
              gitrebase = [];
              gitignore = [];
              gitcommit = [];
              nix = ["alejandra"];
              toml = ["taplo"];
              json = ["prettier"];
              yaml = ["prettier"];
              markdown = ["prettier"];
              sh = ["shfmt"];
              bash = ["shfmt"];
            };
          };
        };

        # Completion engine (nvim-cmp)
        autocomplete.nvim-cmp = {
          enable = true;
          sources = {
            nvim-cmp = null;
            luasnip = "[LuaSnip]";
            buffer = "[Buffer]";
            path = "[Path]";
          };
        };

        # Snippet engine (LuaSnip)
        snippets.luasnip.enable = true;

        # Debug Adapter Protocol (DAP)
        debugger.nvim-dap.enable = true;

        # Telescope: A highly-extensible fuzzy finder
        telescope.enable = true;

        # Neo-tree: A modern file tree explorer
        filetree.neo-tree.enable = true;

        # Oil.nvim: Edit your filesystem like a Neovim buffer
        utility.oil-nvim.enable = true;

        # Gitsigns: Shows git diff information in the sign column
        git.gitsigns.enable = true;

        # Lazygit: A powerful terminal UI for git
        terminal.toggleterm = {
          enable = true;
          lazygit = {
            enable = true;
            mappings.open = "<leader>gg";
          };
        };

        # Comment.nvim: Quickly comment and uncomment code
        comments.comment-nvim.enable = true;

        # Nvim-autopairs: Automatically closes pairs of brackets, etc.
        autopairs.nvim-autopairs.enable = true;

        # Flash: Instantly jump anywhere on screen
        utility.motion.flash-nvim.enable = true;

        # Dressing: Improves the UI for built-in prompts
        extraPlugins.dressing-nvim = {
          package = pkgs.vimPlugins.dressing-nvim;
          setup = "require('dressing').setup {}";
        };
      };
    };
  };
}
