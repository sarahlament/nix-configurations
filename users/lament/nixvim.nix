{
  osConfig,
  pkgs,
  lib,
  ...
}: {
  programs.nixvim = {
    enable = true;
    version.enableNixpkgsReleaseCheck = false;
    defaultEditor = true;
    vimAlias = true;

    opts = {
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
        options.desc = "Find Files";
      }
      {
        key = "<leader>fg";
        action = "<cmd>Telescope live_grep<cr>";
        mode = "n";
        options.desc = "Live Grep";
      }
      {
        key = "<leader>fb";
        action = "<cmd>Telescope buffers<cr>";
        mode = "n";
        options.desc = "Find Buffers";
      }
      {
        key = "<leader>fh";
        action = "<cmd>Telescope help_tags<cr>";
        mode = "n";
        options.desc = "Help Tags";
      }

      # Conform: Format code
      {
        key = "<leader><Tab>";
        action = "<cmd>ConformFormat<cr>";
        mode = [
          "n"
          "v"
        ];
        options.desc = "Format code";
      }

      # Neo-tree: File explorer
      {
        key = "<leader>e";
        action = "<cmd>Neotree toggle<cr>";
        mode = "n";
        options.desc = "Toggle File Explorer";
      }

      # Oil.nvim: Edit filesystem
      {
        key = "-";
        action = "<cmd>Oil<cr>";
        mode = "n";
        options.desc = "Open parent directory";
      }

      # Lazygit
      {
        key = "<leader>gg";
        action = "<cmd>LazyGit<cr>";
        mode = "n";
        options.desc = "Open LazyGit";
      }
    ];

    plugins = {
      # Lualine: A fast and customizable status line
      #lualine.enable = true;

      # Which-key: Displays a popup of possible keybindings
      which-key.enable = true;

      # Noice: A more modern UI for messages and commands
      noice.enable = true;

      # Indent-blankline: Adds indentation guides
      indent-blankline.enable = true;

      # Bufferline: VS Code-style tabs
      bufferline.enable = true;

      # Dressing: Improves the UI for built-in prompts
      dressing.enable = true;

      # Web-devicons: Adds file type icons
      web-devicons.enable = true;

      lsp = {
        enable = true;
        servers = {
          nil_ls.enable = true;
          nil_ls.settings.formatting.command = ["alejandra"];
          nil_ls.settings.nix.flake = {
            autoArchive = true;
            nixpkgsInputName = "nixos-unstable";
          };
          taplo.enable = true;
          jsonls.enable = true;
          bashls.enable = true;
          yamlls.enable = true;
          marksman.enable = true;
        };
      };

      # Treesitter: Better syntax highlighting and code parsing
      treesitter.enable = true;

      # Conform: A powerful and fast code formatter
      conform-nvim = {
        enable = true;
        settings = {
          format_on_save = {
            lsp_fallback = true;
            timeout_ms = 500;
          };
          formatters_by_ft = {
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
      cmp = {
        enable = true;
        settings = {
          sources = [
            {name = "nvim_lsp";}
            {name = "luasnip";}
            {name = "buffer";}
            {name = "path";}
          ];
        };
      };

      # Snippet engine (LuaSnip)
      luasnip.enable = true;

      # Debug Adapter Protocol (DAP)
      dap.enable = true;

      # Telescope: A highly-extensible fuzzy finder
      telescope = {
        enable = true;
        extensions.fzf-native.enable = true;
      };

      # Neo-tree: A modern file tree explorer
      neo-tree.enable = true;

      # Oil.nvim: Edit your filesystem like a Neovim buffer
      oil.enable = true;

      # Gitsigns: Shows git diff information in the sign column
      gitsigns.enable = true;

      # Lazygit: A powerful terminal UI for git
      lazygit.enable = true;

      # Comment.nvim: Quickly comment and uncomment code
      comment.enable = true;

      # Nvim-autopairs: Automatically closes pairs of brackets, etc.
      nvim-autopairs.enable = true;

      # Flash: Instantly jump anywhere on screen
      flash.enable = true;
    };
  };
}
