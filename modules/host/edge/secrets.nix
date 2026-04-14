{ lib, config, ... }:
let
  hasEdgeAliyunSecret =
    lib.hasAttrByPath [ "age" "secrets" "edge-aliyun-env" ] config;
  hasEdgeRoutingSecret =
    lib.hasAttrByPath [ "age" "secrets" "edge-routing-env" ] config;
in {
  options.homelab.edge.runtime = {
    aliyunEnvPath = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      readOnly = true;
      default =
        if hasEdgeAliyunSecret then
          config.age.secrets.edge-aliyun-env.path
        else
          null;
    };

    routingEnvPath = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      readOnly = true;
      default =
        if hasEdgeRoutingSecret then
          config.age.secrets.edge-routing-env.path
        else
          null;
    };

    hasAliyunEnv = lib.mkOption {
      type = lib.types.bool;
      readOnly = true;
      default = hasEdgeAliyunSecret;
    };

    hasRoutingEnv = lib.mkOption {
      type = lib.types.bool;
      readOnly = true;
      default = hasEdgeRoutingSecret;
    };
  };
}
