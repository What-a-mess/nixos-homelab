{ lib, config, pkgs, ... }:
let
  runtime = config.homelab.edge.runtime;
  edgeDdnsEnabled = runtime.hasAliyunEnv && runtime.hasRoutingEnv;
  aliyunEnvPath = runtime.aliyunEnvPath;
  routingEnvPath = runtime.routingEnvPath;
in
lib.mkIf edgeDdnsEnabled {
  systemd.services.edge-ddns = {
    description = "Update edge wildcard DNS records from the current public IPv6";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    serviceConfig = {
      Type = "oneshot";
    };

    path = [
      pkgs.coreutils
      pkgs.curl
    ];

    script = ''
      set -eu

      load_env_file() {
        set -a
        . "$1"
        set +a
      }

      load_env_file "${aliyunEnvPath}"
      load_env_file "${routingEnvPath}"

      public_ipv6="$(curl -6 -fsS https://api64.ipify.org)"
      if [ -z "$public_ipv6" ]; then
        echo "edge-ddns: public IPv6 lookup returned empty output" >&2
        exit 1
      fi

      echo "edge-ddns: loaded Alibaba Cloud env from ${aliyunEnvPath}"
      echo "edge-ddns: loaded routing env from ${routingEnvPath}"
      echo "edge-ddns: would update wildcard DNS records to ${public_ipv6}"
      echo "edge-ddns: wildcard update behavior is scaffolded for later tasks"
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
