{
  stateVersion = "25.11";
  timeZone = "Asia/Shanghai";

  host = {
    hostName = "homelab";
    listenAddress = "0.0.0.0";
    lanCidr = "192.168.31.0/24";
    workgroup = "WORKGROUP";
    network = {
      uplinkInterface = "enp4s0";
      bridgeInterface = "br0";
      address = "192.168.31.210";
      prefixLength = 24;
      gateway = "192.168.31.1";
      dns = [ "192.168.31.1" ];
    };
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
      "/srv/data/router"
      "/srv/data/router/mihomo"
      "/srv/data/vmstate"
    ];
  };

  users = {
    admin = {
      name = "wamess";
    };

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

    app = {
      name = "app";
      uid = 994;
      gid = 994;
    };
  };

  mediaVm = {
    memory = 4096;
    vcpu = 4;
    address = "192.168.31.212";
    stateVolume = {
      image = "/srv/data/vmstate/media-vm-state.img";
      mountPoint = "/var/lib/media-stack";
      size = 16384;
      fsType = "ext4";
      label = "media-vm-state";
    };
  };

  storageVm = {
    memory = 2304;
    vcpu = 2;
    address = "192.168.31.211";
  };

  appVm = {
    memory = 2304;
    vcpu = 2;
    address = "192.168.31.213";
    hostSecretsPath = "/run/app-vm-secrets";
    guestSecretsPath = "/run/host-secrets";
    stateVolume = {
      image = "/srv/data/vmstate/app-vm-state.img";
      mountPoint = "/var/lib/app-services";
      size = 8192;
      fsType = "ext4";
      label = "app-vm-state";
    };
  };

  routerVm = {
    memory = 1536;
    vcpu = 2;
    address = "192.168.31.214";
    configHostPath = "/srv/data/router/mihomo";
    configGuestPath = "/var/lib/router-vm/mihomo-config";
    stateVolume = {
      image = "/srv/data/vmstate/router-vm-state.img";
      mountPoint = "/var/lib/router-vm";
      size = 8192;
      fsType = "ext4";
      label = "router-vm-state";
    };
  };

  ports = {
    storage = {
      guest = {
        smb = [ 139 445 ];
        nfsTcp = [ 111 2049 20048 32765 32766 ];
        nfsUdp = [ 111 2049 20048 32765 32766 ];
      };

      host = {
        smb = [ 30139 30445 ];
        nfsTcp = [ 30111 32049 32048 32765 32766 ];
        nfsUdp = [ 30111 32049 32048 32765 32766 ];
      };
    };

    media = {
      guest = {
        jellyfin = 8096;
        qbittorrent = 8080;
        sonarr = 8989;
        radarr = 7878;
        prowlarr = 9696;
      };

      host = {
        jellyfin = 18096;
        qbittorrent = 18080;
        sonarr = 18989;
        radarr = 17878;
        prowlarr = 19696;
      };
    };

    app = {
      guest = {
        rsshub = 1200;
      };

      host = {
        rsshub = 11200;
      };
    };
  };

  images = {
    rsshub = "ghcr.io/diygod/rsshub:chromium-bundled";
    jellyfin = "docker.io/jellyfin/jellyfin:latest";
    prowlarr = "lscr.io/linuxserver/prowlarr:latest";
    qbittorrent = "lscr.io/linuxserver/qbittorrent:latest";
    radarr = "lscr.io/linuxserver/radarr:latest";
    sonarr = "lscr.io/linuxserver/sonarr:latest";
  };

  edge = {
    port = 28443;
    manageApex = false;
    domain = "example.com";
    services = {
      rsshub = {
        host = "rsshub";
        backendHost = "192.168.31.213";
        backendPort = 1200;
        requireMtls = false;
      };

      jellyfin = {
        host = "jellyfin";
        backendHost = "192.168.31.212";
        backendPort = 8096;
        requireMtls = false;
      };

      sonarr = {
        host = "sonarr";
        backendHost = "192.168.31.212";
        backendPort = 8989;
        requireMtls = false;
      };

      radarr = {
        host = "radarr";
        backendHost = "192.168.31.212";
        backendPort = 7878;
        requireMtls = false;
      };

      prowlarr = {
        host = "prowlarr";
        backendHost = "192.168.31.212";
        backendPort = 9696;
        requireMtls = false;
      };

      qbittorrent = {
        host = "qb";
        backendHost = "192.168.31.212";
        backendPort = 8080;
        requireMtls = false;
      };

      router = {
        host = "router";
        backendHost = "192.168.31.214";
        backendPort = 9090;
        requireMtls = false;
      };
    };
  };
}
