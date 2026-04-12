{ homelab, ... }:
let
  inherit (homelab) mediaVm ports;
in {
  microvm = {
    hypervisor = "qemu";
    vcpu = mediaVm.vcpu;
    mem = mediaVm.memory;
    interfaces = [
      {
        id = "vm-media0";
        mac = "02:00:00:00:20:01";
        type = "tap";
      }
    ];

    shares = [
      {
        proto = "virtiofs";
        source = homelab.storage.root;
        mountPoint = "/data";
        tag = "homelab-data";
        securityModel = "none";
      }
    ];

    volumes = [
      {
        image = mediaVm.stateVolume.image;
        mountPoint = mediaVm.stateVolume.mountPoint;
        size = mediaVm.stateVolume.size;
        fsType = mediaVm.stateVolume.fsType;
        label = mediaVm.stateVolume.label;
      }
    ];
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      ports.media.guest.jellyfin
      ports.media.guest.qbittorrent
      ports.media.guest.radarr
      ports.media.guest.sonarr
      ports.media.guest.prowlarr
    ];
  };
}
