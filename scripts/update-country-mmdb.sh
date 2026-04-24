#!/usr/bin/env bash
set -euo pipefail

DEST="${DEST:-/srv/data/router/mihomo/Country.mmdb}"
BASE_URL="${BASE_URL:-https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

MMDB_URL="$BASE_URL/country.mmdb"
SHA_URL="$BASE_URL/country.mmdb.sha256sum"
MMDB_TMP="$TMP_DIR/country.mmdb"
SHA_TMP="$TMP_DIR/country.mmdb.sha256sum"

mkdir -p "$(dirname "$DEST")"

curl -fsSL "$MMDB_URL" -o "$MMDB_TMP"
curl -fsSL "$SHA_URL" -o "$SHA_TMP"

(
  cd "$TMP_DIR"
  sha256sum -c "$(basename "$SHA_TMP")"
)

install -m 0644 "$MMDB_TMP" "$DEST"

echo "updated:"
echo "  $DEST"
