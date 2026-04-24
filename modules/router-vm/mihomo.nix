{ homelab, lib, pkgs, ... }:
let
  inherit (homelab) routerVm;
  configFile = "${routerVm.configGuestPath}/config.yaml";
  geoipFile = "${routerVm.configGuestPath}/Country.mmdb";
  runtimeDataDir = "/var/lib/private/mihomo";
  runtimeGeoipFile = "${runtimeDataDir}/Country.mmdb";
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
      PermissionsStartOnly = true;
      WorkingDirectory = "${stateRoot}/mihomo";
      ReadWritePaths = [ runtimeDataDir ];
    };
    path = [ pkgs.coreutils ];
    preStart = ''
      install -d -m 0755 "${runtimeDataDir}"
      install -m 0644 "${geoipFile}" "${runtimeGeoipFile}"
    '';
  };
}
