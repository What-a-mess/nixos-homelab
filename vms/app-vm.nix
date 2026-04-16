{ ... }:
{
  imports = [
    ../modules/app-vm/identity.nix
    ../modules/app-vm/microvm.nix
    ../modules/app-vm/state.nix
    ../modules/app-vm/ssh.nix
    ../modules/app-vm/containers.nix
  ];
}
