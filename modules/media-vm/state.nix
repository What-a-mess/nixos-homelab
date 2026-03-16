{ homelab, ... }:
let
  mediaUser = homelab.users.media.name;
  stateRoot = homelab.mediaVm.stateVolume.mountPoint;
  serviceNames = [ "jellyfin" "jellyfin-cache" "prowlarr" "qbittorrent" "radarr" "sonarr" ];
  mkStateDir = name: "d ${stateRoot}/${name} 2775 ${mediaUser} ${mediaUser} - -";
in {
  systemd.tmpfiles.rules = map mkStateDir serviceNames;
}
