{ homelab, ... }:
let
  inherit (homelab) stateVersion users;
  mediaUser = users.media.name;
  mediaUid = users.media.uid;
  mediaGid = users.media.gid;
in {
  networking.hostName = "media-vm";
  time.timeZone = homelab.timeZone;

  users.groups.${mediaUser}.gid = mediaGid;
  users.users.${mediaUser} = {
    isSystemUser = true;
    uid = mediaUid;
    group = mediaUser;
  };

  users.users.root.initialPassword = "root";

  system.stateVersion = stateVersion;
}
