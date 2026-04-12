{ homelab, lib, ... }:
let
  inherit (homelab) host mediaVm ports;
  mkMediaForward = hostPort: guestPort: {
    from = "host";
    host.address = host.listenAddress;
    host.port = hostPort;
    guest.port = guestPort;
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

    forwardPorts = lib.zipListsWith mkMediaForward [
      ports.media.host.jellyfin
      ports.media.host.qbittorrent
      ports.media.host.radarr
      ports.media.host.sonarr
      ports.media.host.prowlarr
    ] [
      ports.media.guest.jellyfin
      ports.media.guest.qbittorrent
      ports.media.guest.radarr
      ports.media.guest.sonarr
      ports.media.guest.prowlarr
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
