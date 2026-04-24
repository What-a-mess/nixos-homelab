{ homelab, pkgs, ... }:
let
  inherit (homelab) appVm images ports;
  stateRoot = homelab.appVm.stateVolume.mountPoint;
  podmanGraphRoot = "${stateRoot}/containers/storage";
  rsshubEnvFile = "${appVm.guestSecretsPath}/rsshub.env";
in {
  virtualisation.podman = {
    enable = true;
    dockerCompat = false;
    defaultNetwork.settings.dns_enabled = true;
    autoPrune.enable = true;
  };

  virtualisation.containers.storage.settings = {
    storage = {
      driver = "overlay";
      runroot = "/run/containers/storage";
      graphroot = podmanGraphRoot;
    };
  };

  virtualisation.oci-containers.backend = "podman";
  virtualisation.oci-containers.containers = {
    rsshub = {
      image = images.rsshub;
      autoStart = true;
      environmentFiles = [ rsshubEnvFile ];
      environment = {
        NODE_ENV = "production";
        TZ = homelab.timeZone;
        PORT = toString ports.app.guest.rsshub;
        CACHE_EXPIRE = "3600";
      };
      volumes = [
        "${stateRoot}/rsshub:/app/.cache:rw"
        "${stateRoot}/rsshub-browser-cache:/tmp:rw"
      ];
      extraOptions = [ "--network=host" ];
    };
  };

  systemd.services.podman-rsshub = {
    environment = {
      HTTP_PROXY = "http://192.168.31.214:7890";
      HTTPS_PROXY = "http://192.168.31.214:7890";
      NO_PROXY = "127.0.0.1,localhost,192.168.31.0/24,192.168.31.213";
    };
    serviceConfig.RestartSec = 15;
    startLimitBurst = 5;
    startLimitIntervalSec = 300;
    unitConfig.ConditionPathExists = rsshubEnvFile;
  };

  environment.systemPackages = with pkgs; [
    podman
  ];
}
