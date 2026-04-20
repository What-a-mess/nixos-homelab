{ lib, config, pkgs, ... }:
let
  edge = config.homelab.edge;
  runtime = edge.runtime;
  certName = edge.domain;
  wildcardDomain = "*.${edge.domain}";
  acmeEnabled = runtime.hasAliyunEnv && edge.acme.email != null;
  acmeEnvFile = "/run/edge-acme/alidns.env";
  certDir = "/var/lib/acme/${certName}";
  serverCert = "${edge.paths.serverPkiDir}/fullchain.pem";
  serverKey = "${edge.paths.serverPkiDir}/privkey.pem";
  stagingServer = "https://acme-staging-v02.api.letsencrypt.org/directory";
in
lib.mkIf acmeEnabled {
  security.acme = {
    acceptTerms = true;
    defaults.email = edge.acme.email;
    certs.${certName} = {
      domain = wildcardDomain;
      extraDomainNames = lib.optional edge.manageApex edge.domain;
      dnsProvider = "alidns";
      environmentFile = acmeEnvFile;
      group = "caddy";
      server = if edge.acme.staging then stagingServer else null;
      postRun = ''
        ${pkgs.coreutils}/bin/install -d -m 0755 ${edge.paths.serverPkiDir}
        ${pkgs.coreutils}/bin/install -m 0644 "${certDir}/fullchain.pem" "${serverCert}"
        ${pkgs.coreutils}/bin/install -m 0640 -g caddy "${certDir}/key.pem" "${serverKey}"
        ${config.systemd.package}/bin/systemctl reload caddy.service || true
      '';
    };
  };

  systemd.services.edge-acme-credentials = {
    description = "Prepare Alibaba Cloud DNS credentials for ACME";
    requiredBy = [ "acme-${certName}.service" ];
    before = [ "acme-${certName}.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    path = [ pkgs.coreutils ];
    script = ''
      set -eu

      install -d -m 0755 /run/edge-acme

      set -a
      . "${runtime.aliyunEnvPath}"
      set +a

      access_key="''${ALICLOUD_ACCESS_KEY:-''${ALICLOUD_ACCESS_KEY_ID:-}}"
      secret_key="''${ALICLOUD_SECRET_KEY:-''${ALICLOUD_ACCESS_KEY_SECRET:-}}"

      if [ -z "$access_key" ] || [ -z "$secret_key" ]; then
        echo "edge-acme-credentials: missing Alibaba Cloud DNS credentials" >&2
        exit 1
      fi

      cat > "${acmeEnvFile}" <<EOF
      ALICLOUD_ACCESS_KEY=$access_key
      ALICLOUD_SECRET_KEY=$secret_key
      EOF

      chmod 0400 "${acmeEnvFile}"
    '';
  };
}
