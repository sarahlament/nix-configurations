{ ... }: {
  # nushell, ishtar-only trial (imported from homeConfigurations/ishtar.nix, NOT
  # sharedModules - servers stay pure zsh). lamentHome already sets
  # home.shell.enableShellIntegration, which cascades to enableNushellIntegration,
  # so the existing starship prompt + zoxide auto-wire in the moment nushell is
  # enabled - no glue here. kitty is pointed at nu in lamentDesktop.
  flake.homeModules.nushell = { lib, ... }: {
    programs = {
      nushell = {
        enable = true;

        settings = {
          show_banner = false;
          edit_mode = "emacs"; # match zsh's default bindings
          history = {
            file_format = "sqlite";
            max_size = 100000;
          };
          completions.external.enable = true;
        };

        # own nu's alias surface outright (mkForce) instead of inheriting
        # home.shellAliases - that generic set (feeding bash/zsh) carries the
        # broken `PAGER=cat ...` prefixes and alias-chained `gs = g stat` into nu,
        # and would shadow the native `ls`. nu's needs differ, so define them here.
        # trade-off: aliases added to home.shellAliases later won't reach nu.
        shellAliases = lib.mkForce {
          c = "clear";
          ff = "hyfetch";
          shutdown = "systemctl poweroff";
          reboot = "systemctl reboot";

          cat = "bat";
          grep = "rg --color=auto";
          la = "eza -a";
          ll = "eza -l";
          lla = "eza -la";
          lt = "eza --tree --level=1";
          ltt = "eza --tree";
          kssh = "kitten ssh";

          # git muscle-memory, ported from git.nix's home.shellAliases (which only
          # feeds bash/zsh). the g-chain rides git's own `stat`/`prettylog`
          # aliases; the three pager-suppressed ones become `--no-pager` (nushell
          # has no inline `PAGER=cat cmd` prefix).
          g = "git";
          gs = "git stat";
          gsw = "git switch";
          gswc = "git switch -c";
          gp = "git pull";
          gput = "git push";
          ga = "git add";
          gau = "git add -u";
          gc = "git commit --verbose";
          gchk = "git checkout";
          gst = "git stash";
          gcm = "git commit --verbose -m";
          gd = "git diff";
          gds = "git diff --stat";
          gdc = "git diff --cached";
          gamend = "git commit --verbose --amend";
          gdsc = "git --no-pager diff --stat --cached";
          gdcs = "git --no-pager diff --cached --stat";
          glog = "git --no-pager prettylog -n10";
        };
      };

      # fzf generates its nu integration via `fzf --nushell`, and the pinned
      # fzf's bundled script still uses `str downcase` (deprecated in nu 0.114) -
      # it spews a wall of deprecation warning on every startup. drop the nu
      # integration until fzf upstream catches up; zsh's fzf is untouched and
      # nu's reedline has its own ctrl-r history search.
      fzf.enableNushellIntegration = false;

      # completions for external commands - make-or-break for the first
      # impression. scoped to nushell only; leave zsh's completion stack untouched.
      carapace = {
        enable = true;
        enableNushellIntegration = true;
        enableZshIntegration = false;
        enableBashIntegration = false;
      };
    };
  };
}
