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

# switch ishtar's standalone home-manager (user config, no system rebuild)
# first run: `nix run home-manager -- switch --flake .#lament@ishtar -b hmb`
home *args:
    home-manager switch --flake ".#lament@ishtar" -b hmb {{ args }}

# run the repl on a host
osrepl host=`hostname -s`:
    nixos-rebuild repl --flake "$FLAKE/.#{{ host }}"

# keys are generated HERE, not on the target: sshd.nix sets generateHostKeys =
# false, so a host receives its identity from sops on first boot rather than
# making its own. nothing needs the box to exist yet.
#
# the age identity is generated independently, NOT derived from the ssh host key
# via ssh-to-age. that's deliberate: a leaked ssh host key must not also hand over
# everything the host can decrypt. keeping them separate also means the sops
# identity survives ssh host key rotation, and it's what the rest of the fleet
# already does - `sops.age.keyFile = /persist/key.age`, placed at install.
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

    ssh-keygen -t ed25519 -N "" -C "{{ host }}" -f "$tmp/ssh" >/dev/null
    sshPub=$(cut -d' ' -f1,2 < "$tmp/ssh.pub")

    # the host's sops identity - goes to /persist/key.age on the target
    age-keygen -o "$tmp/age.key" 2>/dev/null
    hostAge=$(age-keygen -y "$tmp/age.key")

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
    # the host's own age key, kept here for disaster recovery: if /persist is lost
    # the box can't decrypt anything, and this is the only copy that isn't on it.
    # circular for the host, but lament can always read it.
    sops --config /dev/null set "$tmp/out.yaml" '["{{ host }}AgeKey"]' "$(jq -Rs . < "$tmp/age.key")"

    mv "$tmp/out.yaml" "$file"
    # the install needs the age key in the clear, to scp onto the installer.
    # ceremony/ is gitignored - check that before ever moving this path, it is
    # the only thing keeping a private key out of a commit.
    mkdir -p ceremony
    install -m600 "$tmp/age.key" "ceremony/{{ host }}-key.age"

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

    at install time, before first boot - without this the host decrypts nothing,
    which on a headless box means no sshd host key and no way in:

      scp ceremony/{{ host }}-key.age root@<installer>:/tmp/
      install -m600 /tmp/{{ host }}-key.age /mnt/persist/key.age

    ceremony/{{ host }}-key.age is 0600 and gitignored. it also lives in ${file}
    as {{ host }}AgeKey for disaster recovery, so the ceremony copy is safe to
    shred once the host is up.
    EOF

# disko and install are run as SEPARATE phases so the age key can be seeded
# BETWEEN them: disko formats + mounts the subvols at /mnt, then we copy the key
# onto the now-mounted /persist subvol, then install. a single-shot --extra-files
# would write to the tmpfs root before the subvols mount, and @persist shadows it.
# NOT kexec (boot the NixOS installer ISO first). reboots into the installed
# system once done - the key is placed before install, so nothing waits on a
# manual step. the key is the ONLY seed - sshd.nix makes no host key, sops does
# the rest. (LUKS hosts halt at the passphrase prompt on first boot until the TPM
# slot is enrolled - use the Proxmox console.)
# partition + install a fresh host over nixos-anywhere (boot the installer ISO first)
install host ip *args:
    #!/usr/bin/env bash
    set -euo pipefail
    umask 077

    key="ceremony/{{ host }}-key.age"
    if [ ! -e "$key" ]; then
        echo "$key missing - run 'just newhost {{ host }}' first, or it was shredded" >&2
        echo "(recover: sops decrypt --extract '[\"{{ host }}AgeKey\"]' sops/privkeys/{{ host }}.yaml)" >&2
        exit 1
    fi

    # throwaway keypair for the installer session - not a personal key, discarded
    # on exit. ignore host keys: a reinstall reuses the name/ip but the installer's
    # host key is fresh each boot, so skip the stale known_hosts check and don't
    # pollute it. (the *installed* host key is deterministic from sops, so it's
    # stable across reinstalls - only the ISO's ephemeral key is the problem.)
    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT
    ssh-keygen -q -t ed25519 -N "" -C "install-{{ host }}" -f "$tmp/id"
    ignore="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
    sshopt="$ignore -i $tmp/id"

    # authorize the throwaway key on the installer - enter the ISO root password
    # ONCE here (set it with `passwd` on the ISO console first), then every step
    # below is key-based and non-interactive.
    ssh-copy-id -i "$tmp/id.pub" $ignore root@{{ ip }}

    na="nix run github:nix-community/nixos-anywhere --"
    # --build-on local: drive the build here so it offloads to brigid via
    # nix.buildMachines, never on the fresh (weak) target. auto would fall back to
    # a remote build ON the target. substituters copy to the target by default.
    # feed nixos-anywhere the same throwaway key + host-key-ignore as the scp/ssh.
    common="--build-on local -i $tmp/id --ssh-option StrictHostKeyChecking=no --ssh-option UserKnownHostsFile=/dev/null"

    # 1. disko: format + mount the subvols at /mnt (left mounted for the copy)
    $na --flake ".#{{ host }}" $common --phases disko root@{{ ip }} {{ args }}

    # 2. drop the key onto the mounted /persist subvol, before install
    scp $sshopt "$key" root@{{ ip }}:/mnt/persist/key.age
    ssh $sshopt root@{{ ip }} chmod 600 /mnt/persist/key.age

    # 3. install against the mounted target, then reboot into it
    $na --flake ".#{{ host }}" $common --phases install,reboot root@{{ ip }} {{ args }}

sops file="none":
    if [ {{ file }} == none ]; then \
        echo "No file specified"; \
    else \
        sops edit "sops/{{ file }}.yaml"; \
    fi
