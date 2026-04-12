{ lib, config, homelab, pkgs, ... }:
let
  appSecretsHostPath = homelab.appVm.hostSecretsPath;
  secretFile = ../../secrets/rsshub.env.age;
  hasSecretFile = builtins.pathExists secretFile;
  rsshubSecret =
    if hasSecretFile then
      config.age.secrets.rsshub-env.path
    else
      null;
in {
  age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  age.secrets = lib.mkIf hasSecretFile {
    rsshub-env = {
      file = secretFile;
      path = "/run/agenix/rsshub.env";
      mode = "0640";
      owner = "root";
      group = "root";
    };
  };

  systemd.tmpfiles.rules = [
    "d ${appSecretsHostPath} 0750 root root - -"
  ];

  systemd.services.export-app-vm-rsshub-secret = lib.mkIf hasSecretFile {
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
      install -m 0640 "${rsshubSecret}" "${appSecretsHostPath}/rsshub.env"
    '';
    path = [ pkgs.coreutils ];
  };
}
