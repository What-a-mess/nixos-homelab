{ lib, config, ... }:
let
  edge = config.homelab.edge;
  paths = edge.paths;
  secretFile = ../../secrets/trojan-password.age;
  hasSecretFile = builtins.pathExists secretFile;
  passwordPath =
    if hasSecretFile then
      config.age.secrets.trojan-password.path
    else
      null;
  serverCert = "${paths.serverPkiDir}/fullchain.pem";
  serverKey = "${paths.serverPkiDir}/privkey.pem";
  trojanServerName = "${edge.trojan.host}.${edge.domain}";
in
{
  services.sing-box = lib.mkIf (edge.trojan.enable && hasSecretFile) {
    enable = true;
    settings = {
      log = {
        level = "warn";
      };
      inbounds = [
        {
          type = "trojan";
          tag = "trojan-in";
          listen = "::";
          listen_port = edge.trojan.port;
          users = [
            {
              name = "wamess";
              password = { _secret = passwordPath; };
            }
          ];
          tls = {
            enabled = true;
            server_name = trojanServerName;
            alpn = [ "h2" "http/1.1" ];
            min_version = "1.2";
            certificate_path = serverCert;
            key_path = serverKey;
          };
        }
      ];
      outbounds = [
        {
          type = "direct";
          tag = "direct";
        }
      ];
      route = {
        final = "direct";
      };
    };
  };

  systemd.services.sing-box = lib.mkIf (edge.trojan.enable && hasSecretFile) {
    after = [ "acme-finished-${edge.domain}.target" ];
    wants = [ "acme-finished-${edge.domain}.target" ];
    serviceConfig = {
      SupplementaryGroups = [ "caddy" ];
    };
  };

  warnings = lib.optional (edge.trojan.enable && !hasSecretFile)
    "homelab.edge.trojan.enable is true but secrets/trojan-password.age is missing; Trojan proxy will stay disabled until the password secret is created.";
}
