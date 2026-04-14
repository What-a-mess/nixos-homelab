{ homelab, ... }:
let
  inherit (homelab) routerVm;
in {
  microvm = {
    hypervisor = "qemu";
    vcpu = routerVm.vcpu;
    mem = routerVm.memory;
    interfaces = [
      {
        id = "vm-router0";
        mac = "02:00:00:00:40:01";
        type = "tap";
      }
    ];

    volumes = [
      {
        image = routerVm.stateVolume.image;
        mountPoint = routerVm.stateVolume.mountPoint;
        size = routerVm.stateVolume.size;
        fsType = routerVm.stateVolume.fsType;
        label = routerVm.stateVolume.label;
      }
    ];

    shares = [
      {
        proto = "virtiofs";
        source = routerVm.configHostPath;
        mountPoint = routerVm.configGuestPath;
        tag = "router-mihomo-config";
        securityModel = "none";
      }
    ];
  };
}
