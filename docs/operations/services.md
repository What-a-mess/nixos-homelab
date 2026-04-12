# Services

This document answers the question: where is this service configured?

## RSSHub

- Boundary: `app-vm`
- VM entrypoint: [`vms/app-vm.nix`](../../vms/app-vm.nix)
- Runtime module: [`modules/app-vm/containers.nix`](../../modules/app-vm/containers.nix)
- State module: [`modules/app-vm/state.nix`](../../modules/app-vm/state.nix)
- VM networking and port forwarding: [`modules/app-vm/microvm.nix`](../../modules/app-vm/microvm.nix)
- Shared ports and image values: [`lib/homelab-config.nix`](../../lib/homelab-config.nix)
- Host-side secret-related files: [`modules/host/secrets.nix`](../../modules/host/secrets.nix) and [`secrets/secrets.nix`](../../secrets/secrets.nix); the RSSHub runtime secret flow is still being established.

RSSHub is the first workload in the app-tier VM and should remain there unless the application boundary changes materially.

## Media Stack

- Boundary: `media-vm`
- VM entrypoint: [`vms/media-vm.nix`](../../vms/media-vm.nix)
- Runtime modules: [`modules/media-vm/containers.nix`](../../modules/media-vm/containers.nix), [`modules/media-vm/state.nix`](../../modules/media-vm/state.nix), and [`modules/media-vm/microvm.nix`](../../modules/media-vm/microvm.nix)
- Shared ports and image values: [`lib/homelab-config.nix`](../../lib/homelab-config.nix)

The media stack owns media-facing application services such as Jellyfin and the automation tools around it.

## Storage Protocols

- Boundary: `storage-vm`
- VM entrypoint: [`vms/storage-vm.nix`](../../vms/storage-vm.nix)
- SMB: [`modules/storage-vm/samba.nix`](../../modules/storage-vm/samba.nix)
- NFS: [`modules/storage-vm/nfs.nix`](../../modules/storage-vm/nfs.nix)
- Shared data exposure: [`modules/storage-vm/shares.nix`](../../modules/storage-vm/shares.nix) and [`modules/storage-vm/microvm.nix`](../../modules/storage-vm/microvm.nix)
- Shared ports and host storage values: [`lib/homelab-config.nix`](../../lib/homelab-config.nix)

The storage VM owns network file-sharing protocols and access to the shared data root.
