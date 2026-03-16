## Why

This repository needs a concrete first-stage architecture for a single-machine homelab that can host NAS services and a media automation stack without collapsing into an unstructured collection of host-level services. The system should be designed around declarative microVM boundaries now so that service groups can later be migrated as units without redesigning the foundation.

## What Changes

- Introduce a declarative microVM-based homelab foundation built on a single NixOS host.
- Define the host as a substrate for storage mounts, microVM runtime, and VM networking rather than as the main application runtime.
- Introduce a `storage-vm` capability that exports LAN file-sharing protocols for shared directories and selected media directories.
- Introduce a `media-vm` capability that runs the media automation stack and Jellyfin as containers within a dedicated microVM.
- Define the persistent data model for a separate data disk, including shared media, downloads, user-facing shares, and VM/application state.
- Define directory-sharing and ownership boundaries between host, microVMs, and containers to preserve media automation workflows while still allowing LAN access to media files.
- Restrict the initial scope to LAN-only access and first-stage workloads; future miscellaneous application VMs remain out of scope.

## Capabilities

### New Capabilities
- `homelab-host-foundation`: Single-host substrate for disks, microVM runtime, and inter-VM networking.
- `storage-vm-shares`: Dedicated microVM that exports NAS protocols for user-facing shares and selected media directories.
- `media-vm-stack`: Dedicated microVM that runs Jellyfin and the servarr/downloader stack as containers with stable shared storage semantics.
- `homelab-data-layout`: Persistent directory, mount, and access model shared across host, VMs, and containers.

### Modified Capabilities

None.

## Impact

- Introduces a new foundational architecture for the repository.
- Adds a dependency on `microvm.nix` and a microVM-capable virtualization stack.
- Establishes the required storage and directory conventions for all future service groups.
- Constrains future application deployment patterns to fit the host/VM/container layering defined here.
