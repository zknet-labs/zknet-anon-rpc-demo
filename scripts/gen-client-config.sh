#!/bin/bash
# ZKNet Anon-RPC Demo — generate client.toml from .env template
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

# Load .env
if [ -f .env ]; then
  set -a
  . ./.env
  set +a
fi

# Defaults
VPS_GATEWAY_IP="${VPS_GATEWAY_IP:-185.92.181.101}"
VPS_GATEWAY_PORT="${VPS_GATEWAY_PORT:-30004}"
LISTEN_PORT="${LISTEN_PORT:-127.0.0.1:64332}"

TEMPLATE="config/mixnet/client/client.toml.template"
DEST="config/mixnet/client/client.toml"

if [ ! -f "$TEMPLATE" ]; then
  echo "Template not found: $TEMPLATE" >&2
  exit 1
fi

echo "── Generating $DEST from template ──"
sed \
  -e "s|{{VPS_GATEWAY_IP}}|${VPS_GATEWAY_IP}|g" \
  -e "s|{{VPS_GATEWAY_PORT}}|${VPS_GATEWAY_PORT}|g" \
  -e "s|{{LISTEN_PORT}}|${LISTEN_PORT}|g" \
  "$TEMPLATE" > "$DEST"

echo "  [OK] $DEST generated"