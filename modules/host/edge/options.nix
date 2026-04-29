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

    allowedSourceRanges = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "127.0.0.1/8"
        "::1/128"
        homelab.host.lanCidr
      ];
      description = "CIDR ranges allowed to reach edge services through Caddy.";
    };

    acme = {
      email = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "admin@example.com";
        description = "Contact email used for ACME registration and renewal reminders.";
      };

      staging = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to use the Let's Encrypt staging ACME directory.";
      };
    };

    trojan = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to expose a Trojan proxy endpoint on the host.";
      };

      host = lib.mkOption {
        type = lib.types.str;
        default = "trojan";
        description = "Hostname prefix used for the Trojan endpoint under the edge domain.";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 24443;
        description = "Public TCP port used by the Trojan endpoint.";
      };
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
            default = false;
            description = "Whether this edge service requires client certificate authentication.";
          };
        };
      }));
      default = edge.services;
      description = "Declarative mapping of public edge hostnames to backend services.";
    };
  };
}
