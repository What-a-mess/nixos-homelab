{ homelab, ... }:
let
  inherit (homelab) appVm host ports;
in {
  microvm = {
    hypervisor = "qemu";
    vcpu = appVm.vcpu;
    mem = appVm.memory;
    interfaces = [
      {
        id = "app0";
        mac = "02:00:00:00:30:01";
        type = "user";
      }
    ];

    volumes = [
      {
        image = appVm.stateVolume.image;
        mountPoint = appVm.stateVolume.mountPoint;
        size = appVm.stateVolume.size;
        fsType = appVm.stateVolume.fsType;
        label = appVm.stateVolume.label;
      }
    ];

    forwardPorts = [
      {
        from = "host";
        host.address = host.listenAddress;
        host.port = ports.app.host.rsshub;
        guest.port = ports.app.guest.rsshub;
        proto = "tcp";
      }
    ];
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ ports.app.guest.rsshub ];
  };
}
