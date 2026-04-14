# Architecture Map

This document explains the major system boundaries in the homelab and where those boundaries are configured in the repository.

## Repository Roles

- `hosts/` defines top-level host composition.
- `modules/` contains implementation modules grouped by host or VM boundary.
- `vms/` defines the entrypoint for each service-group VM.
- `lib/homelab-config.nix` stores shared constants such as ports, image names, and VM settings.
- `secrets/` stores secret declarations and SSH authorized keys, with the encrypted secret flow still in progress.

## Host

The host is assembled from [`hosts/homelab/default.nix`](../../hosts/homelab/default.nix).

Host-level behavior is implemented in:

- [`modules/host/boot.nix`](../../modules/host/boot.nix)
- [`modules/host/admin-user.nix`](../../modules/host/admin-user.nix)
- [`modules/host/ssh.nix`](../../modules/host/ssh.nix)
- [`modules/host/networking.nix`](../../modules/host/networking.nix)
- [`modules/host/storage.nix`](../../modules/host/storage.nix)
- [`modules/host/microvm-host.nix`](../../modules/host/microvm-host.nix)
- [`modules/host/power.nix`](../../modules/host/power.nix)
- [`modules/host/secrets.nix`](../../modules/host/secrets.nix)

The host is responsible for:

- Booting the physical machine
- Mounting `/srv/data`
- Running the MicroVM host substrate
- Managing host networking, the LAN bridge, and guest tap attachment
- Providing declarative bridge networking while keeping `NetworkManager` and `nmcli` available for inspection and ad-hoc management outside the bridged uplink
- Defining the current secret-handling boundary, including the encrypted secret flow as it is being established

## Storage VM

The storage VM entrypoint is [`vms/storage-vm.nix`](../../vms/storage-vm.nix).

Its implementation modules live under [`modules/storage-vm/`](../../modules/storage-vm).

The storage VM is responsible for:

- Serving SMB and NFS
- Exposing shared storage data
- Mounting the host data root into the VM

## Media VM

The media VM entrypoint is [`vms/media-vm.nix`](../../vms/media-vm.nix).

Its implementation modules live under [`modules/media-vm/`](../../modules/media-vm).

The media VM is responsible for:

- Running the media application stack
- Keeping media-related runtime state private to the VM
- Exposing media services directly on its fixed LAN address

## App VM

The app VM entrypoint is [`vms/app-vm.nix`](../../vms/app-vm.nix).

Its implementation modules live under [`modules/app-vm/`](../../modules/app-vm).

The app VM is responsible for:

- Running lightweight application-tier services
- Hosting RSSHub as the first app-tier workload
- Keeping application runtime state private to the VM

## Router VM

The router VM entrypoint is [`vms/router-vm.nix`](../../vms/router-vm.nix).

Its implementation modules live under [`modules/router-vm/`](../../modules/router-vm).

The router VM is responsible for:

- Running the LAN route-node and proxy-core workload
- Hosting `mihomo` as a dedicated network-function service
- Mounting host-local proxy config into the VM

## Shared Configuration

Shared constants are defined in [`lib/homelab-config.nix`](../../lib/homelab-config.nix).

This file is the first place to check for:

- Port numbers
- Image names
- VM memory and CPU settings
- Shared VM path conventions
