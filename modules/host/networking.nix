{ homelab, pkgs, ... }:
let
  inherit (homelab) host;
  inherit (host.network) address bridgeInterface dns gateway prefixLength uplinkInterface;
in {
  networking.hostName = host.hostName;
  networking.useDHCP = false;
  networking.useNetworkd = true;
  networking.dhcpcd.enable = false;
  networking.networkmanager.enable = true;
  networking.networkmanager.unmanaged = [
    "interface-name:${uplinkInterface}"
    "interface-name:${bridgeInterface}"
    "interface-name:vm-*"
  ];
  time.timeZone = homelab.timeZone;

  networking.bridges.${bridgeInterface}.interfaces = [ uplinkInterface ];
  networking.interfaces.${bridgeInterface}.ipv4.addresses = [
    {
      inherit address prefixLength;
    }
  ];
  networking.defaultGateway = {
    address = gateway;
    interface = bridgeInterface;
  };
  networking.nameservers = dns;

  systemd.network.enable = true;
  systemd.network.networks."30-microvm-taps" = {
    matchConfig.Name = "vm-*";
    networkConfig.Bridge = bridgeInterface;
    linkConfig.RequiredForOnline = "no";
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 homelab.edge.port ];
  };

  environment.systemPackages = with pkgs; [
    git
    git-lfs
    delta
    networkmanager
    iw
    wirelesstools
  ];
}
