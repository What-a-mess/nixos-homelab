{ homelab, pkgs, ... }:
let
  inherit (homelab) images ports;
  stateRoot = homelab.appVm.stateVolume.mountPoint;
in {
  virtualisation.podman = {
    enable = true;
    dockerCompat = false;
    defaultNetwork.settings.dns_enabled = true;
    autoPrune.enable = true;
  };

  virtualisation.oci-containers.backend = "podman";
  virtualisation.oci-containers.containers = {
    rsshub = {
      image = images.rsshub;
      autoStart = true;
      environment = {
        NODE_ENV = "production";
        TZ = homelab.timeZone;
        PORT = toString ports.app.rsshub;
        CACHE_EXPIRE = "3600";
      };
      volumes = [
        "${stateRoot}/rsshub:/app/.cache:rw"
        "${stateRoot}/rsshub-browser-cache:/tmp:rw"
      ];
      extraOptions = [ "--network=host" ];
    };
  };

  environment.systemPackages = with pkgs; [
    podman
  ];
}
