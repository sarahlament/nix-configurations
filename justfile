set quiet

alias help := default
alias fr := flakerepl
alias or := osrepl

branch := `git branch --show-current`

# base project recipes
[private]
default:
    @just --list

# --force-with-lease
push:
    git push --force-with-lease

# rebase N commits ("origin/main" default)
rebase diff="":
    git rebase -i {{ if diff == "" { "origin/main" } else { "HEAD~" + diff } }}

# format the flake
fmt:
    nix fmt .

# update the lockfile, then commit if changed
update:
    nix flake update
    if git diff --quiet $NH_FLAKE/flake.lock; then \
        echo "No updates found"; \
    else \
        git add $NH_FLAKE/flake.lock && git commit -m "flake: updated"; \
    fi

# eval check
check:
    nix flake check

# run the repl on the flake
flakerepl:
    nix repl --expr 'builtins.getFlake "$NH_FLAKE"'

# switch a *remote* machine
deploy host=`hostname -s` *args:
    nh os switch --hostname={{ host }} --target-host={{ host }} {{ args }}

# switch the *local* machine
switch *args:
    nh os switch {{ args }}

# build a host
build host=`hostname -s` *args:
    nh os build --hostname={{ host }} {{ args }}

# run the repl on a host
osrepl host=`hostname -s`:
    nixos-rebuild repl --flake "$NH_FLAKE/.#{{ host }}"

# nvd diff since main
nvd host=`hostname -s`:
    if [ {{ branch }} = main ]; then \
        echo "Cannot diff on main"; \
    else \
        nh os build --hostname={{ host }}; \
        mv ./result ./result-new; \
        git switch main; \
        nh os build --hostname={{ host }}; \
        git switch {{ branch }}; \
        nvd diff ./result ./result-new; \
        rm ./result ./result-new; \
    fi

# cleanup current branch after merge
cleanup target=branch:
    if [ {{ target }} == main ]; then \
        echo "Refusing to cleanup main"; \
    else \
        git switch main; \
        git pull; \
        git branch -D {{ target }}; \
    fi
