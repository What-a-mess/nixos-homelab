{ lib, config, ... }:
let
  hasEdgeAliyunSecret =
    lib.hasAttrByPath [ "age" "secrets" "edge-aliyun-env" ] config;
  hasEdgeRoutingSecret =
    lib.hasAttrByPath [ "age" "secrets" "edge-routing-env" ] config;
  runtime = rec {
    secrets = {
      aliyun = {
        path =
          if hasEdgeAliyunSecret then
            config.age.secrets.edge-aliyun-env.path
          else
            null;
        present = hasEdgeAliyunSecret;
      };
      routing = {
        path =
          if hasEdgeRoutingSecret then
            config.age.secrets.edge-routing-env.path
          else
            null;
        present = hasEdgeRoutingSecret;
      };
    };

    aliyunEnvPath = secrets.aliyun.path;
    routingEnvPath = secrets.routing.path;
    hasAliyunEnv = secrets.aliyun.present;
    hasRoutingEnv = secrets.routing.present;
  };
in {
  options.homelab.edge.runtime = lib.mkOption {
    readOnly = true;
    type = lib.types.attrs;
    default = runtime;
  };
}
