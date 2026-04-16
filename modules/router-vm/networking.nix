{ ... }:
{
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv4.conf.all.rp_filter" = 0;
    "net.ipv4.conf.default.rp_filter" = 0;
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 7890 7891 9090 ];
    allowedUDPPorts = [ 53 ];
    trustedInterfaces = [ "lo" "tun0" ];
    extraCommands = ''
      iptables -A INPUT -p tcp -s 192.168.31.0/24 --dport 22 -j ACCEPT
      iptables -A FORWARD -j ACCEPT
    '';
    extraStopCommands = ''
      iptables -D INPUT -p tcp -s 192.168.31.0/24 --dport 22 -j ACCEPT || true
      iptables -D FORWARD -j ACCEPT || true
    '';
  };
}
