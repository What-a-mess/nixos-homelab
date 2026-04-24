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
      PermissionsStartOnly = true;
      WorkingDirectory = "${stateRoot}/mihomo";
      ReadWritePaths = [ "${stateRoot}/mihomo" ];
    };
    path = [ pkgs.coreutils ];
    preStart = ''
      install -d -m 0755 -o mihomo -g mihomo "${stateRoot}/mihomo"
      install -d -m 0755 -o mihomo -g mihomo "${stateRoot}/mihomo/run"
      install -d -m 0755 -o mihomo -g mihomo "${stateRoot}/mihomo/cache"
      install -m 0644 "${geoipFile}" "${runtimeGeoipFile}"
      chown mihomo:mihomo "${runtimeGeoipFile}"
    '';
  };
}
