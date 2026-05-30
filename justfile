alias help := default
alias fr := flakerepl
alias or: osrepl

# base project recipes
[private]
default:
    @just --list

push:
    git push --force-with-lease

rebase diff="":
    git rebase -i {{ if diff == "" { "origin/main" } else { "HEAD~" + diff } }}

fmt:
    nix fmt .


# flake related recipes
update:
    nix flake update
    if git diff --quiet $NH_FLAKE/flake.lock; then \
        echo "No updates found"; \
    else \
        git add $NH_FLAKE/flake.lock && git commit -m "flake: updated";\
    fi

check:
    nix flake check

flakerepl:
    nix repl --expr 'builtins.getFlake "$NH_FLAKE"'


# os related recipes
deploy host=`hostname -s` *args: (build host)
    nh os switch --hostname={{host}} --target-host={{host}} {{args}}

switch *args:
    nh os switch {{args}}

build host=`hostname -s` *args:
    nh os build --hostname={{host}} {{args}}

osrepl host=`hostname -s`:
    nixos-rebuild repl --flake "$NH_FLAKE/.#{{host}}"
