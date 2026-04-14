let
  homelabHost = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOQSMURU/A0HfoAO6KtQ+2dRfZHUrFiY2tD/M8/g7xrw 44860987+What-a-mess@users.noreply.github.com";
in {
  "rsshub.env.age".publicKeys = [ homelabHost ];
}
