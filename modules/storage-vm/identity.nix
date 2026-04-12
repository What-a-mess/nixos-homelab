{ homelab, ... }:
let
  inherit (homelab) stateVersion storageVm users;
  mediaGroup = users.media.name;
  mediaGid = users.media.gid;
  nasUser = users.nas.name;
  nasUid = users.nas.uid;
  address = storageVm.address;
  prefixLength = homelab.host.network.prefixLength;
  gateway = homelab.host.network.gateway;
  dns = homelab.host.network.dns;
in {
  networking.hostName = "storage-vm";
  networking.useDHCP = false;
  networking.useNetworkd = true;
  time.timeZone = homelab.timeZone;

  systemd.network.enable = true;
  systemd.network.networks."20-lan" = {
    matchConfig.MACAddress = "02:00:00:00:10:01";
    address = [ "${address}/${toString prefixLength}" ];
    routes = [
      {
        Gateway = gateway;
      }
    ];
    dns = dns;
    networkConfig = {
      DHCP = "no";
      IPv6AcceptRA = false;
    };
  };

  users.groups.${mediaGroup}.gid = mediaGid;
  users.users.${nasUser} = {
    isSystemUser = true;
    uid = nasUid;
    group = mediaGroup;
  };

  users.users.root.initialPassword = "root";

  system.stateVersion = stateVersion;
}
