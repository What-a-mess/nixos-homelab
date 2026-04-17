#!/usr/bin/env bash
set -euo pipefail

PKI_ROOT="${PKI_ROOT:-/srv/data/edge/pki}"
CA_DIR="${CA_DIR:-$PKI_ROOT/client-ca}"
CA_NAME="${CA_NAME:-Homelab Client CA}"
CA_KEY="${CA_KEY:-$CA_DIR/ca.key}"
CA_CERT="${CA_CERT:-$CA_DIR/ca.pem}"
CA_DAYS="${CA_DAYS:-3650}"

mkdir -p "$CA_DIR"
chmod 700 "$CA_DIR"

if [ -e "$CA_KEY" ] || [ -e "$CA_CERT" ]; then
  echo "refusing to overwrite existing CA material in $CA_DIR" >&2
  echo "existing files:" >&2
  ls -l "$CA_DIR" >&2 || true
  exit 1
fi

openssl genrsa -out "$CA_KEY" 4096
chmod 600 "$CA_KEY"

openssl req -x509 -new -nodes \
  -key "$CA_KEY" \
  -sha256 \
  -days "$CA_DAYS" \
  -out "$CA_CERT" \
  -subj "/CN=$CA_NAME"

chmod 644 "$CA_CERT"

echo "created client CA:"
echo "  key:  $CA_KEY"
echo "  cert: $CA_CERT"
