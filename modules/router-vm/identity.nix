{ homelab, ... }:
let
  inherit (homelab) routerVm stateVersion;
  address = routerVm.address;
  prefixLength = homelab.host.network.prefixLength;
  gateway = homelab.host.network.gateway;
  dns = homelab.host.network.dns;
in {
  networking.hostName = "router-vm";
  networking.useDHCP = false;
  networking.useNetworkd = true;
  time.timeZone = homelab.timeZone;

  systemd.network.enable = true;
  systemd.network.networks."20-lan" = {
    matchConfig.MACAddress = "02:00:00:00:40:01";
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

  users.users.root.initialPassword = "root";

  system.stateVersion = stateVersion;
}
