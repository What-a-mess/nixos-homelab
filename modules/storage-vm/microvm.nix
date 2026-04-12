{ homelab, ... }:
let
  inherit (homelab) host ports storage storageVm;
  mkForward = proto: hostPort: guestPort: {
    from = "host";
    host.address = host.listenAddress;
    host.port = hostPort;
    guest.port = guestPort;
    inherit proto;
  };
in {
  microvm = {
    hypervisor = "qemu";
    vcpu = storageVm.vcpu;
    mem = storageVm.memory;
    interfaces = [
      {
        id = "storage0";
        mac = "02:00:00:00:10:01";
        type = "user";
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

    forwardPorts =
      (builtins.zipListsWith (mkForward "tcp") ports.storage.host.smb ports.storage.guest.smb)
      ++ (builtins.zipListsWith (mkForward "tcp") ports.storage.host.nfsTcp ports.storage.guest.nfsTcp)
      ++ (builtins.zipListsWith (mkForward "udp") ports.storage.host.nfsUdp ports.storage.guest.nfsUdp);
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = ports.storage.guest.smb ++ ports.storage.guest.nfsTcp;
    allowedUDPPorts = ports.storage.guest.nfsUdp;
  };
}
