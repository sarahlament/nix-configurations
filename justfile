set quiet

alias help := default
alias fr := flakerepl
alias or := osrepl

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

# format the flake
fmt:
    nix fmt .

# update the lockfile (commit with `jj describe` or `gcfl` after reviewing)
update:
    nix flake update

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

# keys are generated HERE, not on the target: sshd.nix sets generateHostKeys =
# false, so a host receives its identity from sops on first boot rather than
# making its own. that's also what breaks the chicken-and-egg - the host's age
# recipient derives from the ssh key we just made, so nothing needs the box to
# exist yet.
# mint a new host's private keys into sops, print the pubkeys to paste in
newhost host donor="minerva":
    #!/usr/bin/env bash
    set -euo pipefail
    # plaintext private keys pass through $tmp - don't let them land 0644
    umask 077

    file="sops/privkeys/{{ host }}.yaml"
    if [ -e "$file" ]; then
        echo "$file already exists - refusing to clobber an existing identity" >&2
        exit 1
    fi

    # / is tmpfs on every host in this fleet, so the plaintext staging dir is in
    # RAM and never touches the disk
    tmp=$(mktemp -d)
    chmod 700 "$tmp"
    trap 'rm -rf "$tmp"' EXIT

    # ssh host key first: the age recipient is derived from it
    ssh-keygen -t ed25519 -N "" -C "{{ host }}" -f "$tmp/ssh" >/dev/null
    hostAge=$(ssh-to-age < "$tmp/ssh.pub")
    sshPub=$(cut -d' ' -f1,2 < "$tmp/ssh.pub")

    wg genkey > "$tmp/wg"
    wgPub=$(wg pubkey < "$tmp/wg")

    # the builder key is a SHARED credential - its pubkey is pinned as an
    # authorized_key in buildMachines.nix - so the new host gets a copy of the
    # existing one. generating a fresh pair here would just fail to authenticate.
    sops decrypt --extract '["builderKey"]' "sops/privkeys/{{ donor }}.yaml" > "$tmp/builder"

    # first key in .sops.yaml is the admin key, kept as a recipient so the file
    # stays editable locally
    adminAge=$(rg -o -m1 'age1\S+' .sops.yaml)

    # explicit recipients rather than a creation_rule: .sops.yaml can't have a
    # rule for this host yet, since its age key didn't exist until 20 lines ago.
    # JSON is valid YAML, so jq handles quoting the multi-line key for us.
    # --config /dev/null (a GLOBAL flag, so it precedes the subcommand) because
    # sops otherwise reads .sops.yaml and hard-fails with "no matching creation
    # rules found" - which is exactly the state we're in until the rule is added.
    # built under $tmp and moved into place only once complete - a failure
    # partway through must not leave a half-written identity sitting where the
    # "already exists" guard will trip on it next run
    jq -n --rawfile k "$tmp/ssh" '{"{{ host }}SshKey": $k}' > "$tmp/seed.json"
    sops --config /dev/null encrypt --age "$adminAge,$hostAge" \
        --input-type json --output-type yaml "$tmp/seed.json" > "$tmp/out.yaml"

    sops --config /dev/null set "$tmp/out.yaml" '["{{ host }}WgKey"]' "$(jq -Rs . < "$tmp/wg")"
    sops --config /dev/null set "$tmp/out.yaml" '["builderKey"]' "$(jq -Rs . < "$tmp/builder")"

    mv "$tmp/out.yaml" "$file"

    cat <<EOF

    ${file} written. two things still need editing by hand:

    1. .sops.yaml - add the recipient and a creation_rule:

      - &{{ host }}  ${hostAge}

      - path_regex: ^sops/privkeys/{{ host }}\.yaml\$
        key_groups:
        - age: [*lament, *{{ host }}]

       and add *{{ host }} to the pass.yaml rule (it's fleet-wide).

    2. modules/lib/directory.nix - hosts.{{ host }}.keys:

          sshPub = "${sshPub}";
          wgPub = "${wgPub}";

    then: sops updatekeys ${file}
    EOF

sops file="none":
    if [ {{ file }} == none ]; then \
        echo "No file specified"; \
    else \
        sops edit "sops/{{ file }}.yaml"; \
    fi
