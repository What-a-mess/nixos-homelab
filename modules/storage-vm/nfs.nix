{ homelab, pkgs, ... }:
let
  lanCidr = homelab.host.lanCidr;
in {
  services.rpcbind.enable = true;
  services.nfs.server = {
    enable = true;
    statdPort = 32765;
    lockdPort = 32766;
    mountdPort = 20048;
    exports = ''
      /data/shares/public ${lanCidr}(rw,sync,no_subtree_check,no_root_squash)
      /data/shares/private ${lanCidr}(rw,sync,no_subtree_check,no_root_squash)
      /data/media ${lanCidr}(ro,sync,no_subtree_check,no_root_squash)
    '';
  };

  environment.systemPackages = with pkgs; [
    nfs-utils
  ];
}
