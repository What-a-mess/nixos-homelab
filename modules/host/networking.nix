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
      ports.storage.host.smb
      ++ ports.storage.host.nfsTcp
      ++ [
        ports.app.host.rsshub
        ports.media.host.jellyfin
        ports.media.host.qbittorrent
        ports.media.host.radarr
        ports.media.host.sonarr
        ports.media.host.prowlarr
      ];
    allowedUDPPorts = ports.storage.host.nfsUdp;
  };

  environment.systemPackages = with pkgs; [
    git
    git-lfs
    delta
    networkmanager
    iw
    wirelesstools
  ];
}
