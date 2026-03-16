{ homelab, ... }:
let
  inherit (homelab.host) workgroup;
  mediaGroup = homelab.users.media.name;
  nasUser = homelab.users.nas.name;
in {
  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        "workgroup" = workgroup;
        "server string" = "homelab storage";
        "netbios name" = "storage-vm";
        "security" = "user";
        "map to guest" = "Bad User";
        "guest account" = nasUser;
      };

      public = {
        "path" = "/data/shares/public";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "create mask" = "0664";
        "directory mask" = "2775";
        "force user" = nasUser;
        "force group" = mediaGroup;
      };

      private = {
        "path" = "/data/shares/private";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = nasUser;
        "create mask" = "0660";
        "directory mask" = "2770";
        "force user" = nasUser;
        "force group" = mediaGroup;
      };

      media = {
        "path" = "/data/media";
        "browseable" = "yes";
        "read only" = "yes";
        "guest ok" = "yes";
        "force user" = nasUser;
        "force group" = mediaGroup;
      };
    };
  };

  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };
}
