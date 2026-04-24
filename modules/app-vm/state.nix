{ homelab, ... }:
let
  stateRoot = homelab.appVm.stateVolume.mountPoint;
  stateDirs = [
    "${stateRoot}/rsshub"
    "${stateRoot}/rsshub-browser-cache"
    "${stateRoot}/containers"
    "${stateRoot}/containers/storage"
  ];
  mkStateDir = path: "d ${path} 0755 root root - -";
in {
  systemd.tmpfiles.rules = map mkStateDir stateDirs;
}
