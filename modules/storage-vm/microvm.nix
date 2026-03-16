{ homelab, ... }:
let
  inherit (homelab) host ports storage storageVm;
  mkForward = proto: port: {
    from = "host";
    host.address = host.listenAddress;
    host.port = port;
    guest.port = port;
    inherit proto;
  };
in {
  microvm = {
    hypervisor = "qemu";
    vcpu = storageVm.vcpu;
    mem = storageVm.memory;

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
      (map (mkForward "tcp") ports.storage.smb)
      ++ (map (mkForward "tcp") ports.storage.nfsTcp)
      ++ (map (mkForward "udp") ports.storage.nfsUdp);
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = ports.storage.smb ++ ports.storage.nfsTcp;
    allowedUDPPorts = ports.storage.nfsUdp;
  };
}
