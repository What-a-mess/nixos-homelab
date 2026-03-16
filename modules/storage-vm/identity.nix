{ homelab, ... }:
let
  inherit (homelab) stateVersion users;
  mediaGroup = users.media.name;
  mediaGid = users.media.gid;
  nasUser = users.nas.name;
  nasUid = users.nas.uid;
in {
  networking.hostName = "storage-vm";
  time.timeZone = homelab.timeZone;

  users.groups.${mediaGroup}.gid = mediaGid;
  users.users.${nasUser} = {
    isSystemUser = true;
    uid = nasUid;
    group = mediaGroup;
  };

  users.users.root.initialPassword = "root";

  system.stateVersion = stateVersion;
}
