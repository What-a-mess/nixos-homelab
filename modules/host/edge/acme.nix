{ lib, config, ... }:
let
  runtime = config.homelab.edge.runtime;
  public = config.homelab.edge.public;
  domain = public.domain;
  acmeEmail = public.acmeEmail;
  acmeEnabled = runtime.hasAliyunEnv && domain != null && acmeEmail != null;
in
{
  options.homelab.edge.public = {
    domain = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };

    httpsPort = lib.mkOption {
      type = lib.types.nullOr lib.types.port;
      default = null;
    };

    acmeEmail = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };

    hostnames = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
    };
  };

  config = lib.mkIf acmeEnabled {
    security.acme = {
      defaults.email = acmeEmail;

      certs.edge-wildcard = {
        acceptTerms = true;
        credentialsFile = runtime.aliyunEnvPath;
        dnsProvider = "alidns";
        domain = "*.${domain}";
        extraDomainNames = lib.optionals config.homelab.edge.manageApex [ domain ];
        group = "nginx";
      };
    };
  };
}
