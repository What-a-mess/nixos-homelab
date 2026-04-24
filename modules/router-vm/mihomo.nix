{ homelab, lib, pkgs, ... }:
let
  inherit (homelab) routerVm;
  configFile = "${routerVm.configGuestPath}/config.yaml";
  geoipFile = "${routerVm.configGuestPath}/Country.mmdb";
  runtimeGeoipFile = "${routerVm.stateVolume.mountPoint}/mihomo/Country.mmdb";
  stateRoot = routerVm.stateVolume.mountPoint;
in {
  services.mihomo = {
    enable = true;
    tunMode = true;
    webui = pkgs.metacubexd;
    configFile = configFile;
  };

  systemd.services.mihomo = {
    unitConfig.ConditionPathExists = lib.mkForce [
      configFile
      geoipFile
    ];
    serviceConfig = {
      WorkingDirectory = "${stateRoot}/mihomo";
      ReadWritePaths = [ "${stateRoot}/mihomo" ];
    };
    path = [ pkgs.coreutils ];
    preStart = ''
      install -m 0644 "${geoipFile}" "${runtimeGeoipFile}"
    '';
  };
}
