{ homelab, ... }:
let
  inherit (homelab) host ports;
in {
  networking.hostName = host.hostName;
  time.timeZone = homelab.timeZone;

  networking.firewall = {
    enable = true;
    allowedTCPPorts =
      ports.storage.smb
      ++ ports.storage.nfsTcp
      ++ [
        ports.app.rsshub
        ports.media.jellyfin
        ports.media.qbittorrent
        ports.media.radarr
        ports.media.sonarr
        ports.media.prowlarr
      ];
    allowedUDPPorts = ports.storage.nfsUdp;
  };
}
