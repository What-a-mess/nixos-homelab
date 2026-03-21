{
  stateVersion = "25.11";
  timeZone = "Asia/Shanghai";

  host = {
    hostName = "homelab";
    listenAddress = "0.0.0.0";
    lanCidr = "192.168.1.0/24";
    workgroup = "WORKGROUP";
  };

  storage = {
    root = "/srv/data";
    disk = {
      device = "/dev/disk/by-label/homelab-data";
      fsType = "ext4";
    };

    directories = [
      "/srv/data/backups"
      "/srv/data/downloads"
      "/srv/data/downloads/complete"
      "/srv/data/downloads/incomplete"
      "/srv/data/inbox"
      "/srv/data/media"
      "/srv/data/media/movies"
      "/srv/data/media/music"
      "/srv/data/media/tv"
      "/srv/data/shares"
      "/srv/data/shares/private"
      "/srv/data/shares/public"
      "/srv/data/vmstate"
    ];
  };

  users = {
    media = {
      name = "media";
      uid = 1000;
      gid = 1000;
    };

    nas = {
      name = "nas";
      uid = 995;
      gid = 995;
    };
  };

  mediaVm = {
    memory = 4096;
    vcpu = 4;
    stateVolume = {
      image = "/srv/data/vmstate/media-vm-state.img";
      mountPoint = "/var/lib/media-stack";
      size = 16384;
      fsType = "ext4";
      label = "media-vm-state";
    };
  };

  storageVm = {
    memory = 2048;
    vcpu = 2;
  };

  ports = {
    storage = {
      smb = [ 139 445 ];
      nfsTcp = [ 111 2049 20048 32765 32766 ];
      nfsUdp = [ 111 2049 20048 32765 32766 ];
    };

    media = {
      jellyfin = 8096;
      qbittorrent = 8080;
      sonarr = 8989;
      radarr = 7878;
      prowlarr = 9696;
    };
  };

  images = {
    jellyfin = "docker.io/jellyfin/jellyfin:latest";
    prowlarr = "lscr.io/linuxserver/prowlarr:latest";
    qbittorrent = "lscr.io/linuxserver/qbittorrent:latest";
    radarr = "lscr.io/linuxserver/radarr:latest";
    sonarr = "lscr.io/linuxserver/sonarr:latest";
  };
}
