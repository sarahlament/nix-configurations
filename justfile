set quiet

alias help := default
alias fr := flakerepl
alias or := osrepl

branch := `git branch --show-current`

# base project recipes
[private]
default:
    @just --list

# lint-gated push of the bookmark on the current commit (jj skips git hooks, so gate on the full check)
push *args: check
    #!/usr/bin/env bash
    set -euo pipefail
    bookmark=$(jj log --no-graph --color never -r 'latest(bookmarks() & ::@)' -T 'bookmarks.map(|b| b.name()).join("\n")' | head -1)
    jj git push --bookmark "$bookmark" {{ args }}

# fetch remote, then forget any feature bookmarks now merged into main
fetch *args:
    #!/usr/bin/env bash
    set -euo pipefail
    jj git fetch {{ args }}
    # every non-main bookmark that's an ancestor of main is merged; filter main
    # out by NAME so a bookmark co-located with main (fast-forward) still counts
    bookmarks=$(jj log --no-graph --color never -r 'bookmarks() & ::main' \
        -T 'bookmarks.filter(|b| b.name() != "main").map(|b| b.name() ++ "\n").join("")')
    if [ -z "$bookmarks" ]; then
        echo "no feature bookmark to forget"
    else
        while IFS= read -r bookmark; do
            [ -n "$bookmark" ] && jj bookmark forget --include-remotes "$bookmark"
        done <<< "$bookmarks"
    fi

# rebase N commits ("origin/main" default)
rebase diff="":
    git rebase -i {{ if diff == "" { "origin/main" } else { "HEAD~" + diff } }}

# format the flake
fmt:
    nix fmt .

# update the lockfile, then commit if changed
update:
    nix flake update
    if git diff --quiet $FLAKE/flake.lock; then \
        echo "No updates found"; \
    else \
        git add $FLAKE/flake.lock && git commit -m "flake: updated"; \
    fi

# eval check
check:
    jj st
    nix flake check

# run the repl on the flake
flakerepl:
    nix repl --expr 'builtins.getFlake "$FLAKE"'

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
    nixos-rebuild repl --flake "$FLAKE/.#{{ host }}"

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

sops file="none":
    if [ {{ file }} == none ]; then \
        echo "No file specified"; \
    else \
        sops edit "sops/{{ file }}.yaml"; \
    fi