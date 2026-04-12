{ config, homelab, pkgs, ... }:
let
  appSecretsHostPath = homelab.appVm.hostSecretsPath;
  rsshubSecret = config.age.secrets.rsshub-env.path;
in {
  age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  age.secrets.rsshub-env = {
    file = ../../secrets/rsshub.env.age;
    path = "/run/agenix/rsshub.env";
    mode = "0640";
    owner = "root";
    group = "root";
  };

  systemd.tmpfiles.rules = [
    "d ${appSecretsHostPath} 0750 root root - -"
  ];

  systemd.services.export-app-vm-rsshub-secret = {
    description = "Export decrypted RSSHub env file for app-vm";
    wantedBy = [ "multi-user.target" ];
    after = [ "agenix.service" ];
    wants = [ "agenix.service" ];
    partOf = [ "agenix.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      install -d -m 0750 ${appSecretsHostPath}
      if [ -f "${rsshubSecret}" ]; then
        install -m 0640 "${rsshubSecret}" "${appSecretsHostPath}/rsshub.env"
      else
        rm -f "${appSecretsHostPath}/rsshub.env"
      fi
    '';
    path = [ pkgs.coreutils pkgs.findutils ];
  };
}
