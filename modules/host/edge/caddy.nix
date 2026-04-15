{ lib, config, ... }:
let
  paths = config.homelab.edge.paths;
  edgeEnabled = builtins.pathExists paths.caddyfile;
in
lib.mkIf edgeEnabled {
  services.caddy = {
    enable = true;
    configFile = paths.caddyfile;
  };

  systemd.services.caddy.serviceConfig = {
    SupplementaryGroups = [ "caddy" ];
  };
}
