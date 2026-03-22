{ homelab, lib, ... }:
let
  adminAuthorizedKeysPath = ../../secrets/ssh/admin_authorized_keys;
  authorizedKeys =
    if builtins.pathExists adminAuthorizedKeysPath then
      lib.pipe (builtins.readFile adminAuthorizedKeysPath) [
        (lib.splitString "\n")
        (builtins.filter (line: line != "" && !(lib.hasPrefix "#" line)))
      ]
    else
      [ ];
in {
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  users.users.${homelab.users.admin.name}.openssh.authorizedKeys.keys = authorizedKeys;
}
