{ homelab, ... }:
let
  mediaGroup = homelab.users.media.name;
  nasUser = homelab.users.nas.name;
in {
  systemd.tmpfiles.rules = [
    "d /data/shares/public 2775 ${nasUser} ${mediaGroup} - -"
    "d /data/shares/private 2770 ${nasUser} ${mediaGroup} - -"
    "d /data/media 2755 ${nasUser} ${mediaGroup} - -"
  ];
}
