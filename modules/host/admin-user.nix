{ homelab, ... }:
let
  adminUser = homelab.users.admin.name;
in {
  users.users.${adminUser} = {
    isNormalUser = true;
    description = "Homelab administrator";
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
  };
}
