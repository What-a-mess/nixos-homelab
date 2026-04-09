{ homelab, ... }:
let
  stateRoot = homelab.appVm.stateVolume.mountPoint;
  serviceNames = [ "rsshub" "rsshub-browser-cache" ];
  mkStateDir = name: "d ${stateRoot}/${name} 0755 root root - -";
in {
  systemd.tmpfiles.rules = map mkStateDir serviceNames;
}
