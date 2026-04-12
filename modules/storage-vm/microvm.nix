{ homelab, ... }:
let
  inherit (homelab) ports storage storageVm;
in {
  microvm = {
    hypervisor = "qemu";
    vcpu = storageVm.vcpu;
    mem = storageVm.memory;
    interfaces = [
      {
        id = "vm-storage0";
        mac = "02:00:00:00:10:01";
        type = "tap";
      }
    ];

    shares = [
      {
        proto = "virtiofs";
        source = storage.root;
        mountPoint = "/data";
        tag = "homelab-data";
        securityModel = "none";
      }
    ];
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = ports.storage.guest.smb ++ ports.storage.guest.nfsTcp;
    allowedUDPPorts = ports.storage.guest.nfsUdp;
  };
}
