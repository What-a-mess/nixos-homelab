{ lib, ... }:
let
  edgeRoot = "/srv/data/edge";
in
{
  options.homelab.edge.paths = {
    root = lib.mkOption {
      readOnly = true;
      type = lib.types.str;
      default = edgeRoot;
    };

    caddyConfigDir = lib.mkOption {
      readOnly = true;
      type = lib.types.str;
      default = "${edgeRoot}/caddy";
    };

    caddyfile = lib.mkOption {
      readOnly = true;
      type = lib.types.str;
      default = "${edgeRoot}/caddy/Caddyfile";
    };

    serverPkiDir = lib.mkOption {
      readOnly = true;
      type = lib.types.str;
      default = "${edgeRoot}/pki/server";
    };

    clientCaDir = lib.mkOption {
      readOnly = true;
      type = lib.types.str;
      default = "${edgeRoot}/pki/client-ca";
    };

    clientBundlesDir = lib.mkOption {
      readOnly = true;
      type = lib.types.str;
      default = "${edgeRoot}/pki/clients";
    };
  };
}
