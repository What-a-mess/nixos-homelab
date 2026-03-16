{ homelab, ... }:
let
  inherit (homelab) storage users;
  mediaUid = users.media.uid;
  mediaGid = users.media.gid;
in {
  fileSystems."/srv/data" = {
    device = storage.disk.device;
    fsType = storage.disk.fsType;
    neededForBoot = false;
  };

  systemd.tmpfiles.rules = [
    "d ${storage.root} 0755 root root - -"
    "d ${storage.root}/backups 2775 ${toString mediaUid} ${toString mediaGid} - -"
    "d ${storage.root}/downloads 2775 ${toString mediaUid} ${toString mediaGid} - -"
    "d ${storage.root}/downloads/complete 2775 ${toString mediaUid} ${toString mediaGid} - -"
    "d ${storage.root}/downloads/incomplete 2775 ${toString mediaUid} ${toString mediaGid} - -"
    "d ${storage.root}/inbox 2775 ${toString mediaUid} ${toString mediaGid} - -"
    "d ${storage.root}/media 2775 ${toString mediaUid} ${toString mediaGid} - -"
    "d ${storage.root}/media/movies 2775 ${toString mediaUid} ${toString mediaGid} - -"
    "d ${storage.root}/media/music 2775 ${toString mediaUid} ${toString mediaGid} - -"
    "d ${storage.root}/media/tv 2775 ${toString mediaUid} ${toString mediaGid} - -"
    "d ${storage.root}/shares 2775 ${toString mediaUid} ${toString mediaGid} - -"
    "d ${storage.root}/shares/private 2770 ${toString mediaUid} ${toString mediaGid} - -"
    "d ${storage.root}/shares/public 2775 ${toString mediaUid} ${toString mediaGid} - -"
    "d ${storage.root}/vmstate 0755 root root - -"
  ];
}
