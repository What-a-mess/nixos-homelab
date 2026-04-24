{ lib, config, pkgs, ... }:
let
  edge = config.homelab.edge;
  paths = edge.paths;
  serverCert = "${paths.serverPkiDir}/fullchain.pem";
  serverKey = "${paths.serverPkiDir}/privkey.pem";
  clientCa = "${paths.clientCaDir}/ca.pem";
  requiresClientCa = lib.any (service: service.requireMtls) (lib.attrValues edge.services);

  renderServiceBlock = _: service:
    let
      siteHost = "${service.host}.${edge.domain}";
      backend = "${service.backendHost}:${toString service.backendPort}";
      tlsBlock =
        if service.requireMtls then
          ''
             tls ${serverCert} ${serverKey} {
               client_auth {
                 mode require_and_verify
                 trust_pool file ${clientCa}
               }
             }
          ''
        else
          ''
             tls ${serverCert} ${serverKey}
          '';
    in
    ''
      ${siteHost}:${toString edge.port} {
        log {
          output stdout
          format console
        }
      ${tlsBlock}
        reverse_proxy ${backend}
      }
    '';

  caddyfileText =
    let
      renderedServices = lib.mapAttrsToList renderServiceBlock edge.services;
    in
    if renderedServices == [ ] then
      ''
        {
        }
      ''
    else
      lib.concatStringsSep "\n" renderedServices;

  generatedCaddyfile = pkgs.writeText "edge-caddyfile" caddyfileText;
in
{
  services.caddy = {
    enable = true;
    configFile = paths.caddyfile;
  };

  systemd.services.edge-caddyfile = {
    description = "Install generated edge Caddyfile";
    wantedBy = [ "multi-user.target" ];
    before = [ "caddy.service" ];
    restartTriggers = [ generatedCaddyfile ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    path = [ pkgs.coreutils ];

    script = ''
      install -d -m 0750 -g caddy ${paths.caddyConfigDir}
      install -m 0640 -g caddy ${generatedCaddyfile} ${paths.caddyfile}
    '';
  };

  systemd.services.caddy = {
    after = [ "edge-caddyfile.service" ];
    requires = [ "edge-caddyfile.service" ];
    restartTriggers = [ generatedCaddyfile ];
    unitConfig.ConditionPathExists = [
      paths.caddyfile
      serverCert
      serverKey
    ] ++ lib.optional requiresClientCa clientCa;
    serviceConfig = {
      SupplementaryGroups = [ "caddy" ];
    };
  };
}
