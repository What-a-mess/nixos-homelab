{ homelab, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/host/boot.nix
    ../../modules/host/storage.nix
    ../../modules/host/networking.nix
    ../../modules/host/microvm-host.nix
  ];
}
