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
        starship
        nushell # ishtar-only trial - see nushell.nix
        # lament's profile: base + desktop
        lamentHome
        lamentDesktop
      ])
      ++ [
        inputs.nvf.homeManagerModules.default
        self.myLib.nvfModule
        inputs.zen-browser.homeModules.beta
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
        {
          # nvim yanks to the Wayland system clipboard. ishtar-only: the shared
          # nvfModule stays headless-safe, since `unnamedplus` would route every
          # yank through wl-copy, which errors on a server with no Wayland display.
          programs.nvf.settings.vim.clipboard = {
            enable = true;
            registers = "unnamedplus";
            providers.wl-copy.enable = true;
          };
        }
        (
          # ishtar's starship.toml is a WRITABLE seeded copy, not a repo symlink:
          # noctalia's starship template sed-injects the matugen palette straight
          # into the file (starship has no `include`), so a tracked mkOutOfStoreSymlink
          # would churn the repo on every wallpaper change. seed the prompt body
          # until noctalia has injected (its marker), then leave it alone so the
          # live colors aren't clobbered on `just home`. enable the "starship"
          # template in noctalia's control center.
          { pkgs, lib, ... }:
          {
            home.activation.seedStarship = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
              cfg="$HOME/.config/starship.toml"
              if [ ! -e "$cfg" ] || ! ${pkgs.gnugrep}/bin/grep -q "NOCTALIA STARSHIP PALETTE" "$cfg"; then
                $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -Dm644 ${../../dotfiles/starship/starship.toml} "$cfg"
              fi
            '';
          }
        )
        {
          # zen replaces brave (DNS-level adblock carries the network side now).
          # nix owns the browser + force-installed extensions via policy; the
          # profile is left UNMANAGED (no `profiles.*`) so noctalia's zen-browser
          # community template owns the theme surface - its apply.sh injects
          # userChrome/userContent css into the profile's chrome/ dir and flips
          # the legacy-stylesheets pref in user.js, which a hm-managed profile
          # would clobber as a read-only symlink. same "noctalia owns the mutable
          # theme, nix owns the rest" split as bat/btop. ishtar-only.
          #
          # enable the "zen-browser" template in noctalia's control center. no
          # live reload here (firefox-family, unlike kitty/btop) - restart zen to
          # pick up a new palette.
          programs.zen-browser = {
            enable = true;
            setAsDefaultBrowser = true;
            policies = {
              DontCheckDefaultBrowser = true;
              DisableTelemetry = true;
              DisableFirefoxStudies = true;
              DisablePocket = true;
              # force-install from AMO. keys are the extensions' webext ids;
              # cosmetic filtering (uBO) still earns its keep past DNS blocking,
              # bitwarden pairs with vaultwarden on minerva, stylus with matugen.
              ExtensionSettings =
                let
                  fromAMO = builtins.mapAttrs (
                    _: slug: {
                      install_url = "https://addons.mozilla.org/firefox/downloads/latest/${slug}/latest.xpi";
                      installation_mode = "force_installed";
                    }
                  );
                in
                fromAMO {
                  "uBlock0@raymondhill.net" = "ublock-origin";
                  "{446900e4-71c2-419f-a6a7-df9c091e268b}" = "bitwarden-password-manager";
                  "{7a7a4a92-a2a0-41d1-9fd7-1e92480d612d}" = "styl-us";
                };
            };
          };
        }
      ];
  };
}
