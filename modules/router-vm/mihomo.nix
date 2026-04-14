{ homelab, lib, pkgs, ... }:
let
  inherit (homelab) routerVm;
  configFile = "${routerVm.configGuestPath}/config.yaml";
  stateRoot = routerVm.stateVolume.mountPoint;
in {
  services.mihomo = {
    enable = true;
    tunMode = true;
    webui = pkgs.metacubexd;
    configFile = configFile;
  };

  systemd.services.mihomo = {
    unitConfig.ConditionPathExists = lib.mkForce configFile;
    serviceConfig = {
      WorkingDirectory = "${stateRoot}/mihomo";
    };
  };
}
