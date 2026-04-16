{ homelab, ... }:
let
  inherit (homelab) appVm ports;
in {
  microvm = {
    hypervisor = "qemu";
    vcpu = appVm.vcpu;
    mem = appVm.memory;
    interfaces = [
      {
        id = "vm-app0";
        mac = "02:00:00:00:30:01";
        type = "tap";
      }
    ];

    shares = [
      {
        proto = "virtiofs";
        source = appVm.hostSecretsPath;
        mountPoint = appVm.guestSecretsPath;
        tag = "app-vm-secrets";
        securityModel = "none";
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
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ ports.app.guest.rsshub ];
    extraCommands = ''
      iptables -A INPUT -p tcp -s ${homelab.host.lanCidr} --dport 22 -j ACCEPT
    '';
    extraStopCommands = ''
      iptables -D INPUT -p tcp -s ${homelab.host.lanCidr} --dport 22 -j ACCEPT || true
    '';
  };
}
