{ lib, homelab, ... }:
let
  inherit (homelab) edge;
in
{
  options.homelab.edge = {
    domain = lib.mkOption {
      type = lib.types.str;
      default = edge.domain;
      description = "Base public domain used for edge-exposed services.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = edge.port;
      description = "Public TCP port used by the edge TLS terminator.";
    };

    manageApex = lib.mkOption {
      type = lib.types.bool;
      default = edge.manageApex;
      description = "Whether DDNS and certificates should also cover the apex domain.";
    };

    services = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule ({ ... }: {
        options = {
          host = lib.mkOption {
            type = lib.types.str;
            description = "Hostname prefix exposed under the edge domain.";
          };

          backendHost = lib.mkOption {
            type = lib.types.str;
            description = "Backend host or IP that receives proxied traffic.";
          };

          backendPort = lib.mkOption {
            type = lib.types.port;
            description = "Backend TCP port that receives proxied traffic.";
          };

          requireMtls = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Whether this edge service requires client certificate authentication.";
          };
        };
      }));
      default = edge.services;
      description = "Declarative mapping of public edge hostnames to backend services.";
    };
  };
}
