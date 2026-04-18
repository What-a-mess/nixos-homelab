#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  issue-client-cert.sh [--force] <device-name> [common-name]

Environment overrides:
  PKI_ROOT        default: /srv/data/edge/pki
  CA_DIR          default: $PKI_ROOT/client-ca
  CLIENTS_DIR     default: $PKI_ROOT/clients
  CA_KEY          default: $CA_DIR/ca.key
  CA_CERT         default: $CA_DIR/ca.pem
  CERT_DAYS       default: 825
  P12_PASSWORD    default: empty password

Examples:
  issue-client-cert.sh iphone
  issue-client-cert.sh --force iphone
  P12_PASSWORD=secret issue-client-cert.sh macbook "MacBook Pro"
EOF
}

if [ "${1:-}" = "" ] || [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
  exit "${1:+0}"
fi

FORCE=0
if [ "${1:-}" = "--force" ]; then
  FORCE=1
  shift
fi

if [ "${1:-}" = "" ]; then
  usage
  exit 1
fi

DEVICE_NAME="$1"
COMMON_NAME="${2:-$DEVICE_NAME}"

PKI_ROOT="${PKI_ROOT:-/srv/data/edge/pki}"
CA_DIR="${CA_DIR:-$PKI_ROOT/client-ca}"
CLIENTS_DIR="${CLIENTS_DIR:-$PKI_ROOT/clients}"
CA_KEY="${CA_KEY:-$CA_DIR/ca.key}"
CA_CERT="${CA_CERT:-$CA_DIR/ca.pem}"
CERT_DAYS="${CERT_DAYS:-825}"
P12_PASSWORD="${P12_PASSWORD:-}"

DEVICE_DIR="$CLIENTS_DIR/$DEVICE_NAME"
KEY_FILE="$DEVICE_DIR/$DEVICE_NAME.key"
CSR_FILE="$DEVICE_DIR/$DEVICE_NAME.csr"
CERT_FILE="$DEVICE_DIR/$DEVICE_NAME.crt"
P12_FILE="$DEVICE_DIR/$DEVICE_NAME.p12"
EXT_FILE="$DEVICE_DIR/$DEVICE_NAME.ext"
SERIAL_FILE="$CA_DIR/ca.srl"

if [ ! -f "$CA_KEY" ] || [ ! -f "$CA_CERT" ]; then
  echo "client CA not found, initialize it first:" >&2
  echo "  scripts/init-client-ca.sh" >&2
  exit 1
fi

mkdir -p "$DEVICE_DIR"
chmod 700 "$DEVICE_DIR"

if [ "$FORCE" -eq 1 ]; then
  rm -f "$KEY_FILE" "$CSR_FILE" "$CERT_FILE" "$P12_FILE" "$EXT_FILE"
else
  for file in "$KEY_FILE" "$CSR_FILE" "$CERT_FILE" "$P12_FILE" "$EXT_FILE"; do
    if [ -e "$file" ]; then
      echo "refusing to overwrite existing device material: $file" >&2
      echo "rerun with --force to replace this device certificate bundle" >&2
      exit 1
    fi
  done
fi

openssl genrsa -out "$KEY_FILE" 2048
chmod 600 "$KEY_FILE"

openssl req -new \
  -key "$KEY_FILE" \
  -out "$CSR_FILE" \
  -subj "/CN=$COMMON_NAME"

cat > "$EXT_FILE" <<'EOF'
basicConstraints=CA:FALSE
extendedKeyUsage=clientAuth
keyUsage=digitalSignature,keyEncipherment
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid,issuer
EOF

openssl x509 -req \
  -in "$CSR_FILE" \
  -CA "$CA_CERT" \
  -CAkey "$CA_KEY" \
  -CAcreateserial \
  -CAserial "$SERIAL_FILE" \
  -out "$CERT_FILE" \
  -days "$CERT_DAYS" \
  -sha256 \
  -extfile "$EXT_FILE"

chmod 644 "$CERT_FILE"

if [ -n "$P12_PASSWORD" ]; then
  openssl pkcs12 -export \
    -inkey "$KEY_FILE" \
    -in "$CERT_FILE" \
    -certfile "$CA_CERT" \
    -out "$P12_FILE" \
    -passout "pass:$P12_PASSWORD"
else
  openssl pkcs12 -export \
    -inkey "$KEY_FILE" \
    -in "$CERT_FILE" \
    -certfile "$CA_CERT" \
    -out "$P12_FILE" \
    -passout pass:
fi

chmod 600 "$P12_FILE"

echo "issued client certificate for $DEVICE_NAME:"
echo "  key:   $KEY_FILE"
echo "  cert:  $CERT_FILE"
echo "  p12:   $P12_FILE"
echo "  ca:    $CA_CERT"
