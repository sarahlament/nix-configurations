update:
    nix flake update
    if git diff --quiet $NH_FLAKE/flake.lock; then \
        echo "No updates found"; \
    else \
        git add $NH_FLAKE/flake.lock && git commit -m "flake: updated";\
    fi

check:
    nix flake check

fmt:
    nix fmt run $NH_FLAKE

repl:
    nix repl --expr 'builtins.getFlake "$NH_FLAKE"'