{ lib, config, pkgs, ... }:
let
  runtime = config.homelab.edge.runtime;
  edge = config.homelab.edge;
  edgeDdnsEnabled = runtime.hasAliyunEnv;
  aliyunEnvPath = runtime.aliyunEnvPath;
  manageApex = edge.manageApex or false;
in
lib.mkIf edgeDdnsEnabled {
  systemd.services.edge-ddns = {
    description = "Update edge wildcard AAAA DNS records from the current public IPv6";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    serviceConfig = {
      Type = "oneshot";
    };

    path = [
      pkgs.coreutils
      pkgs.curl
      pkgs.gnugrep
      pkgs.jq
      pkgs.python3
    ];

    script = ''
      set -eu

      load_env_file() {
        set -a
        . "$1"
        set +a
      }

      load_env_file "${aliyunEnvPath}"

      access_key_id="''${ALICLOUD_ACCESS_KEY_ID:-''${ALICLOUD_ACCESS_KEY:-}}"
      access_key_secret="''${ALICLOUD_ACCESS_KEY_SECRET:-''${ALICLOUD_SECRET_KEY:-}}"
      if [ -z "$access_key_id" ] || [ -z "$access_key_secret" ]; then
        echo "edge-ddns: missing Alibaba Cloud API credentials" >&2
        exit 1
      fi

      # DNS publication stays independent of Caddy mTLS policy while
      # publishing wildcard and optional apex AAAA records for the
      # configured edge domain.
      domain="${edge.domain}"
      wildcard_rr="*"
      wildcard_subdomain="*.${edge.domain}"
      apex_rr="@"
      apex_subdomain="${edge.domain}"

      public_ipv6="$(curl -6 -fsS https://api64.ipify.org)"
      if [ -z "$public_ipv6" ]; then
        echo "edge-ddns: public IPv6 lookup returned empty output" >&2
        exit 1
      fi

      aliyun_signed_url() {
        action="$1"
        shift
        ACCESS_KEY_ID="$access_key_id" ACCESS_KEY_SECRET="$access_key_secret" \
          python3 - "$action" "$@" <<'PY'
import base64
import hashlib
import hmac
import os
import sys
import urllib.parse
import uuid
from datetime import datetime, timezone

access_key_id = os.environ["ACCESS_KEY_ID"]
access_key_secret = os.environ["ACCESS_KEY_SECRET"]
action = sys.argv[1]
extra = {}
for item in sys.argv[2:]:
    key, value = item.split("=", 1)
    extra[key] = value

params = {
    "AccessKeyId": access_key_id,
    "Action": action,
    "Format": "JSON",
    "SignatureMethod": "HMAC-SHA1",
    "SignatureNonce": str(uuid.uuid4()),
    "SignatureVersion": "1.0",
    "Timestamp": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "Version": "2015-01-09",
}
params.update(extra)

def encode(value: str) -> str:
    return urllib.parse.quote(value, safe="-_.~")

canonical = "&".join(
    f"{encode(str(key))}={encode(str(value))}"
    for key, value in sorted(params.items())
)
string_to_sign = f"GET&%2F&{encode(canonical)}"
signature = base64.b64encode(
    hmac.new(
        f"{access_key_secret}&".encode(),
        string_to_sign.encode(),
        hashlib.sha1,
    ).digest()
).decode()
query = f"{canonical}&Signature={encode(signature)}"
print(f"https://alidns.aliyuncs.com/?{query}")
PY
      }

      call_aliyun() {
        action="$1"
        shift
        curl -fsS "$(aliyun_signed_url "$action" "$@")"
      }

      ensure_aaaa_record() {
        rr="$1"
        subdomain="$2"
        describe_json="$(call_aliyun DescribeSubDomainRecords "SubDomain=$subdomain" "Type=AAAA" "PageSize=100")"

        record_count="$(printf '%s' "$describe_json" | jq '(.DomainRecords.Record // []) | length')"
        if [ "$record_count" -gt 1 ]; then
          echo "edge-ddns: found multiple AAAA records for $subdomain, updating the first one only" >&2
        fi

        record_id="$(printf '%s' "$describe_json" | jq -r '(.DomainRecords.Record // [])[0].RecordId // empty')"
        current_value="$(printf '%s' "$describe_json" | jq -r '(.DomainRecords.Record // [])[0].Value // empty')"

        if [ -z "$record_id" ]; then
          call_aliyun AddDomainRecord \
            "DomainName=$domain" \
            "RR=$rr" \
            "Type=AAAA" \
            "Value=$public_ipv6" \
            >/dev/null
          echo "edge-ddns: created AAAA $subdomain -> $public_ipv6"
        elif [ "$current_value" = "$public_ipv6" ]; then
          echo "edge-ddns: AAAA $subdomain already points to $public_ipv6"
        else
          call_aliyun UpdateDomainRecord \
            "RecordId=$record_id" \
            "RR=$rr" \
            "Type=AAAA" \
            "Value=$public_ipv6" \
            >/dev/null
          echo "edge-ddns: updated AAAA $subdomain from $current_value to $public_ipv6"
        fi
      }

      ensure_aaaa_record "$wildcard_rr" "$wildcard_subdomain"
      ${lib.optionalString manageApex ''
        ensure_aaaa_record "$apex_rr" "$apex_subdomain"
      ''}

      echo "edge-ddns: published AAAA records for ${edge.domain} using ${aliyunEnvPath}"
    '';
  };

  systemd.timers.edge-ddns = {
    description = "Run the edge DDNS updater periodically";
    wantedBy = [ "timers.target" ];

    timerConfig = {
      OnBootSec = "3m";
      OnUnitActiveSec = "10m";
      Persistent = true;
      RandomizedDelaySec = "1m";
      Unit = "edge-ddns.service";
    };
  };
}
