# Services

This document answers the question: where is this service configured?

## RSSHub

- Boundary: `app-vm`
- LAN address: `192.168.31.213`
- VM entrypoint: [`vms/app-vm.nix`](../../vms/app-vm.nix)
- Runtime module: [`modules/app-vm/containers.nix`](../../modules/app-vm/containers.nix)
- State module: [`modules/app-vm/state.nix`](../../modules/app-vm/state.nix)
- VM networking: [`modules/app-vm/microvm.nix`](../../modules/app-vm/microvm.nix) and [`modules/app-vm/identity.nix`](../../modules/app-vm/identity.nix)
- Shared ports and image values: [`lib/homelab-config.nix`](../../lib/homelab-config.nix)
- Host-side secret-related files: [`modules/host/secrets.nix`](../../modules/host/secrets.nix) and [`secrets/secrets.nix`](../../secrets/secrets.nix); the RSSHub runtime secret flow is still being established.

RSSHub is the first workload in the app-tier VM and should remain there unless the application boundary changes materially.

## Media Stack

- Boundary: `media-vm`
- LAN address: `192.168.31.212`
- VM entrypoint: [`vms/media-vm.nix`](../../vms/media-vm.nix)
- Runtime modules: [`modules/media-vm/containers.nix`](../../modules/media-vm/containers.nix), [`modules/media-vm/state.nix`](../../modules/media-vm/state.nix), [`modules/media-vm/microvm.nix`](../../modules/media-vm/microvm.nix), and [`modules/media-vm/identity.nix`](../../modules/media-vm/identity.nix)
- Shared ports and image values: [`lib/homelab-config.nix`](../../lib/homelab-config.nix)

The media stack owns media-facing application services such as Jellyfin and the automation tools around it.

## Storage Protocols

- Boundary: `storage-vm`
- LAN address: `192.168.31.211`
- VM entrypoint: [`vms/storage-vm.nix`](../../vms/storage-vm.nix)
- SMB: [`modules/storage-vm/samba.nix`](../../modules/storage-vm/samba.nix)
- NFS: [`modules/storage-vm/nfs.nix`](../../modules/storage-vm/nfs.nix)
- Shared data exposure: [`modules/storage-vm/shares.nix`](../../modules/storage-vm/shares.nix), [`modules/storage-vm/microvm.nix`](../../modules/storage-vm/microvm.nix), and [`modules/storage-vm/identity.nix`](../../modules/storage-vm/identity.nix)
- Shared ports and host storage values: [`lib/homelab-config.nix`](../../lib/homelab-config.nix)

The storage VM owns network file-sharing protocols and access to the shared data root.

## Router Node

- Boundary: `router-vm`
- LAN address: `192.168.31.214`
- VM entrypoint: [`vms/router-vm.nix`](../../vms/router-vm.nix)
- Runtime modules: [`modules/router-vm/mihomo.nix`](../../modules/router-vm/mihomo.nix), [`modules/router-vm/networking.nix`](../../modules/router-vm/networking.nix), [`modules/router-vm/microvm.nix`](../../modules/router-vm/microvm.nix), [`modules/router-vm/state.nix`](../../modules/router-vm/state.nix), and [`modules/router-vm/identity.nix`](../../modules/router-vm/identity.nix)
- Local config source: `/srv/data/router/mihomo`

The router VM owns route-node and ordinary proxy behavior for opted-in clients.
