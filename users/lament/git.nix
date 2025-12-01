{
  config,
  lib,
  pkgs,
  ...
}: {
  home.shellAliases = {
    g = "git";
    gs = "g stat";
    gp = "g pull";
    gput = "g push";
    ga = "g add";
    gau = "ga -u";
    gc = "g commit --verbose";
    gchk = "g checkout";
    gst = "g stash";
    gcm = "gc -m";
    gd = "g diff";
    gds = "gd --stat";
    gdsc = "PAGER=cat gds --cached";
    gdc = "gd --cached";
    gdcs = "PAGER=cat gdc --stat";
    glog = "PAGER=cat g prettylog -n10";
    gamend = "gc --amend -u";
    gcfl = "ga flake.lock && gcm \"updated flake.lock\"";
  };

  programs = {
    git = {
      enable = true;
      settings = {
        user.name = "Sarah Lament";
        user.email = "sarah@lament.gay";
        init.defaultBranch = "main";
        fetch.prune = true;
        pull.rebase = true;
        push.autoSetupRemote = true;
        alias = {
          sreset = "reset HEAD~1 --soft";
          hreset = "reset HEAD~1 --hard";
          prettylog = "log --oneline --decorate --graph";
          stat = "status --short --branch";
        };
      };
    };

    gh = {
      enable = true;
      settings = {
        git_protocol = "ssh";
        aliases = {
          co = "pr checkout";
          pv = "pr view";
          pc = "pr create";
          pm = "pr merge";
          rc = "repo clone";
          rv = "repo view";
        };
      };
      gitCredentialHelper = {
        enable = true;
        hosts = [
          "https://github.com"
          "https://gist.github.com"
          "https://gitlab.com"
        ];
      };
    };
  };
}
