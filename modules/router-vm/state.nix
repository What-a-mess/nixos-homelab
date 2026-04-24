{ homelab, ... }:
let
  inherit (homelab) routerVm;
  stateRoot = routerVm.stateVolume.mountPoint;
in {
  systemd.tmpfiles.rules = [
    "d ${stateRoot} 0755 root root - -"
    "d ${stateRoot}/mihomo 0755 mihomo mihomo - -"
    "d ${stateRoot}/mihomo/run 0755 mihomo mihomo - -"
    "d ${stateRoot}/mihomo/cache 0755 mihomo mihomo - -"
  ];
}
