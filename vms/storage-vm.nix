{ ... }:
{
  imports = [
    ../modules/storage-vm/identity.nix
    ../modules/storage-vm/microvm.nix
    ../modules/storage-vm/shares.nix
    ../modules/storage-vm/samba.nix
    ../modules/storage-vm/nfs.nix
  ];
}
