{ inputs, self, ... }: {
  # ishtar's lament HM, applied standalone (`just home` -> home-manager switch),
  # decoupled from nixos-rebuild so editor/user tweaks don't need a system build.
  # servers keep the integrated path (users/lament.nix). nvf rides along here
  # (shared config via myLib.nvfModule) so nvim iterates without a system rebuild.
  flake.homeConfigurations."lament@ishtar" = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = import inputs.nixpkgs {
      system = "x86_64-linux";
      config.allowUnfree = true;
      overlays = [
        self.overlays.default
        self.overlays.pinned
      ];
    };
    extraSpecialArgs = { inherit inputs self; };
    modules =
      (with self.homeModules; [
        # mirrors the sharedModules list in core.nix (fleet-wide user modules)
        btop
        fastfetch
        homeShell
        hyfetch
        posh
        # lament's profile: base + desktop
        lamentHome
        lamentDesktop
      ])
      ++ [
        inputs.nvf.homeManagerModules.default
        self.myLib.nvfModule
        {
          home = {
            stateVersion = "26.05";
            sessionVariables.EDITOR = "nvim";
            # the home-manager CLI, so `home-manager switch` works from the profile
            packages = [ inputs.home-manager.packages.x86_64-linux.default ];
          };
          programs.nvf.enable = true;
        }
        (
          # nvim follows noctalia's matugen palette, split the same way as kitty's
          # rice: noctalia renders the base16 palette to ~/.config/nvim/lua/matugen.lua
          # (enable the "neovim" community template once in noctalia's control center),
          # and nvf declaratively supplies base16-nvim + loads that file at startup.
          # ishtar-only - servers have no noctalia, so this stays out of nvfModule.
          { pkgs, ... }:
          {
            programs.nvf.settings.vim.extraPlugins.base16-nvim = {
              package = pkgs.vimPlugins.base16-nvim;
              setup = ''
                local palette = vim.fn.expand("~/.config/nvim/lua/matugen.lua")

                -- ride kitty's translucency instead of painting base16's solid bg.
                local function transparent()
                  for _, group in ipairs({
                    "Normal",
                    "NormalNC",
                    "NormalFloat",
                    "SignColumn",
                    "EndOfBuffer",
                  }) do
                    vim.api.nvim_set_hl(0, group, { bg = "none" })
                  end
                end

                -- load noctalia's generated base16 palette. it's absent until the
                -- template's rendered once (-> nvim default), so guard with pcall.
                -- the file also self-registers a SIGUSR1 handler that require()s
                -- 'matugen' - which nvf's wrapper (NVIM_APPNAME=nvf) can't resolve,
                -- and it re-registers on every reload. stub new_signal across the
                -- load so that handler no-ops; we own the reload below instead.
                local function load()
                  local new_signal = vim.uv.new_signal
                  vim.uv.new_signal = function()
                    return { start = function() end, stop = function() end, close = function() end }
                  end
                  local ok, matugen = pcall(dofile, palette)
                  vim.uv.new_signal = new_signal
                  if ok and matugen then matugen.setup() end
                end

                local function apply()
                  load()
                  transparent()
                end
                apply()

                -- hot-reload: noctalia re-renders the palette then SIGUSR1s us on
                -- every theme/wallpaper change. re-load colors, then reapply transparency.
                local reload = vim.uv.new_signal()
                reload:start("sigusr1", vim.schedule_wrap(apply))
              '';
            };
          }
        )
        {
          # point btop at noctalia's matugen theme (enable the "btop" template in
          # noctalia's control center; it renders ~/.config/btop/themes/noctalia.theme).
          # set here rather than let noctalia's apply.sh sed btop.conf - it's an
          # HM-managed read-only symlink, so with this already set apply.sh no-ops.
          # bat needs nothing: its config isn't HM-owned, so noctalia's template
          # writes --theme=noctalia + builds the cache itself. ishtar-only.
          programs.btop.settings.color_theme = "noctalia";
        }
      ];
  };
}
