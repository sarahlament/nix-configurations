#!/usr/bin/env bash
# Generate builder and deployer SSH keypairs.
# Run from the repo root. Paste the pubkey output to Lux, then
# run ceremony/02-update-sops.sh to add the private keys to sops.
set -euo pipefail

KEYDIR=$(mktemp -d)
echo "keys -> $KEYDIR"
echo ""

ssh-keygen -q -t ed25519 -f "$KEYDIR/builderKey"  -C "builder@pantheon"  -N ""
ssh-keygen -q -t ed25519 -f "$KEYDIR/deployerKey" -C "deployer@pantheon" -N ""

echo "=== builderKey.pub ==="
cat "$KEYDIR/builderKey.pub"
echo ""
echo "=== deployerKey.pub ==="
cat "$KEYDIR/deployerKey.pub"
echo ""
echo "paste both pubkeys to Lux, then run:"
echo "  ceremony/02-update-sops.sh $KEYDIR"
