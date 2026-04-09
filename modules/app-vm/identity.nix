{ homelab, ... }:
let
  inherit (homelab) stateVersion users;
  appUser = users.app.name;
  appUid = users.app.uid;
  appGid = users.app.gid;
in {
  networking.hostName = "app-vm";
  time.timeZone = homelab.timeZone;

  users.groups.${appUser}.gid = appGid;
  users.users.${appUser} = {
    isSystemUser = true;
    uid = appUid;
    group = appUser;
  };

  users.users.root.initialPassword = "root";

  system.stateVersion = stateVersion;
}
