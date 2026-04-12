{ homelab, ... }:
let
  inherit (homelab) mediaVm stateVersion users;
  mediaUser = users.media.name;
  mediaUid = users.media.uid;
  mediaGid = users.media.gid;
  address = mediaVm.address;
  prefixLength = homelab.host.network.prefixLength;
  gateway = homelab.host.network.gateway;
  dns = homelab.host.network.dns;
in {
  networking.hostName = "media-vm";
  networking.useDHCP = false;
  networking.useNetworkd = true;
  time.timeZone = homelab.timeZone;

  systemd.network.enable = true;
  systemd.network.networks."20-lan" = {
    matchConfig.MACAddress = "02:00:00:00:20:01";
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

  users.groups.${mediaUser}.gid = mediaGid;
  users.users.${mediaUser} = {
    isSystemUser = true;
    uid = mediaUid;
    group = mediaUser;
  };

  users.users.root.initialPassword = "root";

  system.stateVersion = stateVersion;
}
