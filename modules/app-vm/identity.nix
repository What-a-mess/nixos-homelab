{ homelab, ... }:
let
  inherit (homelab) appVm stateVersion users;
  appUser = users.app.name;
  appUid = users.app.uid;
  appGid = users.app.gid;
  address = appVm.address;
  prefixLength = homelab.host.network.prefixLength;
  gateway = homelab.host.network.gateway;
  dns = homelab.host.network.dns;
in {
  networking.hostName = "app-vm";
  networking.useDHCP = false;
  networking.useNetworkd = true;
  time.timeZone = homelab.timeZone;

  systemd.network.enable = true;
  systemd.network.networks."20-lan" = {
    matchConfig.MACAddress = "02:00:00:00:30:01";
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

  users.groups.${appUser}.gid = appGid;
  users.users.${appUser} = {
    isSystemUser = true;
    uid = appUid;
    group = appUser;
  };

  users.users.root.initialPassword = "root";

  system.stateVersion = stateVersion;
}
