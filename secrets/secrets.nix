let
  homelabHost = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINu30TLbM5r6+ekyfP+IWrnyxLznk2cZmwPV/ItbJy2m root@homelab";
in {
  "rsshub.env.age".publicKeys = [ homelabHost ];
  "edge-aliyun.env.age".publicKeys = [ homelabHost ];
  "trojan-password.age".publicKeys = [ homelabHost ];
}
