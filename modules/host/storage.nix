{ homelab, lib, config, ... }:
let
  inherit (homelab) storage users;
  mediaUid = users.media.uid;
  mediaGid = users.media.gid;
  hasEdgePaths = lib.hasAttrByPath [ "homelab" "edge" "paths" ] config;
  edgeDirectories =
    if hasEdgePaths then
      [
        config.homelab.edge.paths.root
        config.homelab.edge.paths.caddyConfigDir
        "${config.homelab.edge.paths.root}/pki"
        config.homelab.edge.paths.serverPkiDir
        config.homelab.edge.paths.clientCaDir
        config.homelab.edge.paths.clientBundlesDir
      ]
    else
      [ ];
  mkStorageRule =
    path:
    let
      groupWritablePaths = [
        "${storage.root}/backups"
        "${storage.root}/downloads"
        "${storage.root}/downloads/complete"
        "${storage.root}/downloads/incomplete"
        "${storage.root}/inbox"
        "${storage.root}/media"
        "${storage.root}/media/movies"
        "${storage.root}/media/music"
        "${storage.root}/media/tv"
        "${storage.root}/shares"
        "${storage.root}/shares/public"
      ];
      privateSharePath = "${storage.root}/shares/private";
      vmStatePath = "${storage.root}/vmstate";
      mode =
        if path == storage.root then
          "0755"
        else if path == vmStatePath then
          "0775"
        else if path == privateSharePath then
          "2770"
        else if builtins.elem path groupWritablePaths then
          "2775"
        else
          "0755";
      owner =
        if path == vmStatePath then
          "microvm"
        else if mode == "0755" then
          "root"
        else
          toString mediaUid;
      group =
        if path == vmStatePath then
          "kvm"
        else if mode == "0755" then
          "root"
        else
          toString mediaGid;
    in
    "d ${path} ${mode} ${owner} ${group} - -";
in {
  fileSystems."/srv/data" = {
    device = lib.mkDefault storage.disk.device;
    fsType = lib.mkDefault storage.disk.fsType;
    neededForBoot = lib.mkDefault false;
  };

  systemd.tmpfiles.rules = map mkStorageRule ([ storage.root ] ++ storage.directories ++ edgeDirectories);
}
