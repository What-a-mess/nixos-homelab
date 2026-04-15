{ lib, config, ... }:
let
  hasEdgeAliyunSecret =
    lib.hasAttrByPath [ "age" "secrets" "edge-aliyun-env" ] config;
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
    };

    aliyunEnvPath = secrets.aliyun.path;
    hasAliyunEnv = secrets.aliyun.present;
  };
in {
  options.homelab.edge.runtime = lib.mkOption {
    readOnly = true;
    type = lib.types.attrs;
    default = runtime;
  };
}
