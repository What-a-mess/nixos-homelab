{ homelab, pkgs, ... }:
let
  inherit (homelab) images ports users;
  mediaUid = users.media.uid;
  mediaGid = users.media.gid;
  stateRoot = homelab.mediaVm.stateVolume.mountPoint;
in {
  virtualisation.podman = {
    enable = true;
    dockerCompat = false;
    defaultNetwork.settings.dns_enabled = true;
    autoPrune.enable = true;
  };

  virtualisation.oci-containers.backend = "podman";
  virtualisation.oci-containers.containers = {
    jellyfin = {
      image = images.jellyfin;
      autoStart = true;
      environment = {
        TZ = homelab.timeZone;
      };
      volumes = [
        "${stateRoot}/jellyfin:/config:rw"
        "${stateRoot}/jellyfin-cache:/cache:rw"
        "/data/media:/data/media:ro"
      ];
      extraOptions = [ "--network=host" ];
    };

    qbittorrent = {
      image = images.qbittorrent;
      autoStart = true;
      environment = {
        PUID = toString mediaUid;
        PGID = toString mediaGid;
        TZ = homelab.timeZone;
        WEBUI_PORT = toString ports.media.guest.qbittorrent;
      };
      volumes = [
        "${stateRoot}/qbittorrent:/config:rw"
        "/data/downloads:/data/downloads:rw"
      ];
      extraOptions = [ "--network=host" ];
    };

    sonarr = {
      image = images.sonarr;
      autoStart = true;
      environment = {
        PUID = toString mediaUid;
        PGID = toString mediaGid;
        TZ = homelab.timeZone;
      };
      volumes = [
        "${stateRoot}/sonarr:/config:rw"
        "/data:/data:rw"
      ];
      extraOptions = [ "--network=host" ];
    };

    radarr = {
      image = images.radarr;
      autoStart = true;
      environment = {
        PUID = toString mediaUid;
        PGID = toString mediaGid;
        TZ = homelab.timeZone;
      };
      volumes = [
        "${stateRoot}/radarr:/config:rw"
        "/data:/data:rw"
      ];
      extraOptions = [ "--network=host" ];
    };

    prowlarr = {
      image = images.prowlarr;
      autoStart = true;
      environment = {
        PUID = toString mediaUid;
        PGID = toString mediaGid;
        TZ = homelab.timeZone;
      };
      volumes = [
        "${stateRoot}/prowlarr:/config:rw"
      ];
      extraOptions = [ "--network=host" ];
    };
  };

  environment.systemPackages = with pkgs; [
    podman
  ];
}
