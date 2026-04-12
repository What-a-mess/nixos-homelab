let
  homelabHost = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAPLACEHOLDER replace-me-after-first-boot";
in {
  "rsshub.env.age".publicKeys = [ homelabHost ];
}
