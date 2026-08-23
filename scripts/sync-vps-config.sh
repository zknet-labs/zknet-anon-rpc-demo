#!/bin/bash
# ZKNetwork / Anon-RPC Demo — sync VPS mixnet client config into this repo.
#
# Pulls the proven full-client kpclientd config from your VPS mixnet and
# materializes it as config/mixnet/client/client.toml (the sole client config).
# The only local edit is the thin-client listen port (64332 — repo convention)
# so application services keep working unchanged.
#
# BACKUP/RESTORE:
#   This script IS the backup mechanism — it snapshots the VPS client config
#   into the repo. To restore after a VPS rebuild:
#     1. Rebuild the VPS mixnet (~/katzenpost/manager.sh rebuild)
#     2. Run this script to pull the new client config
#     3. ./stop.sh && ./start.sh
#   VPS authority/gateway keys are NOT backed up here — they live only on the
#   VPS. If the VPS is lost, the mixnet must be rebuilt from scratch with new
#   keys, and all clients must re-sync.
#
# Run this whenever the VPS mixnet is rebuilt with fresh keys:
#   VPS_HOST=user@your-vps-host ./scripts/sync-vps-config.sh
#
# Requires SSH access to the VPS. Set VPS_HOST (user@host or SSH alias)
# matching an entry in ~/.ssh/config. Example:
#   VPS_HOST=myuser@192.0.2.100 ./scripts/sync-vps-config.sh
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

# Load .env
if [ -f .env ]; then
  set -a
  . ./.env
  set +a
fi

VPS_HOST="${VPS_HOST:?Set VPS_HOST=user@your-vps-host before running}"
VPS_CLIENT="${VPS_CLIENT:-katzenpost/vps-config/client/client.toml}"
DEST="config/mixnet/client/client.toml"
LISTEN_PORT="${LISTEN_PORT:-127.0.0.1:64332}"

echo "── Syncing VPS client config ──"
echo "  VPS: $VPS_HOST:$VPS_CLIENT"
echo "  →   $DEST (listen $LISTEN_PORT)"

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

scp -q "${VPS_HOST}:~/${VPS_CLIENT}" "$tmp"
sed -i "s|Address = \"127.0.0.1:64331\"|Address = \"${LISTEN_PORT}\"|" "$tmp"

if ! grep -q "tcp://.*:30004" "$tmp"; then
  echo "  [WARN] no gateway address (tcp://*:30004) found in synced config — check VPS config." >&2
fi
if ! grep -q 'PacketLength = 31082' "$tmp"; then
  echo "  [WARN] expected geometry (31082) not found — verify against MIXNET_TUNING.md." >&2
fi

cp "$tmp" "$DEST"
echo "  [OK] $DEST updated. Verify with: git diff --stat"