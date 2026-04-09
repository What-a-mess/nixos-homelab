{ pkgs, self, homelab, microvmModules, ... }:
{
  imports = [
    microvmModules.host
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  environment.systemPackages = with pkgs; [
    qemu_kvm
  ];

  microvm.vms = {
    storage-vm = {
      flake = self;
    };

    media-vm = {
      flake = self;
    };

    app-vm = {
      flake = self;
    };
  };

  system.stateVersion = homelab.stateVersion;
}
