{ homelab, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/host/boot.nix
    ../../modules/host/admin-user.nix
    ../../modules/host/ssh.nix
    ../../modules/host/power.nix
    ../../modules/host/storage.nix
    ../../modules/host/networking.nix
    ../../modules/host/vscode.nix
    ../../modules/host/microvm-host.nix
    ../../modules/host/secrets.nix
    ../../modules/host/edge/default.nix
  ];
}
