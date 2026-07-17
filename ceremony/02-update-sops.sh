#!/usr/bin/env bash
# Add builderKey and deployerKey to sops/privkeys.yaml.
# Run AFTER Lux has updated the config files and you've confirmed eval passes.
# Usage: ceremony/02-update-sops.sh <keydir>  (the dir printed by 01-gen-keys.sh)
set -euo pipefail

KEYDIR="${1:?usage: $0 <keydir from 01-gen-keys.sh>}"
SOPS_FILE="sops/privkeys.yaml"

add_key() {
  local name="$1" file="$2"
  local value
  value=$(python3 -c "import json; print(json.dumps(open('${file}').read()))")
  sops --set "[\"${name}\"] ${value}" "$SOPS_FILE"
  echo "  added ${name}"
}

echo "adding keys to $SOPS_FILE..."
add_key builderKey  "$KEYDIR/builderKey"
add_key deployerKey "$KEYDIR/deployerKey"

echo ""
echo "shredding plaintext keys..."
shred -u "$KEYDIR/builderKey" "$KEYDIR/deployerKey"
rm -f "$KEYDIR/builderKey.pub" "$KEYDIR/deployerKey.pub"
rmdir "$KEYDIR"
echo "done."
echo ""
echo "nixbldKey is still in sops - remove it after a successful deploy:"
echo "  sops sops/privkeys.yaml  (delete the nixbldKey line, save)"
