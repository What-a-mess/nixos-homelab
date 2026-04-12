{ homelab, pkgs, ... }:
let
  inherit (homelab) host ports;
in {
  networking.hostName = host.hostName;
  networking.networkmanager.enable = true;
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

  environment.systemPackages = with pkgs; [
    networkmanager
    iw
    wirelesstools
  ];
}
