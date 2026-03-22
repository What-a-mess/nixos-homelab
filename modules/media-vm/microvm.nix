{ homelab, ... }:
let
  inherit (homelab) host mediaVm ports;
  mkMediaForward = port: {
    from = "host";
    host.address = host.listenAddress;
    host.port = port;
    guest.port = port;
    proto = "tcp";
  };
in {
  microvm = {
    hypervisor = "qemu";
    vcpu = mediaVm.vcpu;
    mem = mediaVm.memory;
    interfaces = [
      {
        id = "media0";
        mac = "02:00:00:00:20:01";
        type = "user";
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

    forwardPorts = map mkMediaForward [
      ports.media.jellyfin
      ports.media.qbittorrent
      ports.media.radarr
      ports.media.sonarr
      ports.media.prowlarr
    ];
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      ports.media.jellyfin
      ports.media.qbittorrent
      ports.media.radarr
      ports.media.sonarr
      ports.media.prowlarr
    ];
  };
}
