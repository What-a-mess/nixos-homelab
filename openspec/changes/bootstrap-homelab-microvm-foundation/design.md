## Context

The target system is a long-lived single physical machine running a NixOS-based homelab. The machine has one disk for the operating system and one hard disk for bulk data such as downloads, media libraries, shared files, and backup staging. The user wants service groups to be isolated in declarative microVMs using `microvm.nix`, with services inside each VM running as containers rather than directly on the host.

The first stage must support two major workloads:

- NAS access for LAN clients via SMB and NFS
- A media stack consisting of Jellyfin, Sonarr, Radarr, Prowlarr, and a downloader

The system is LAN-only for now. Future expansion is expected to happen by moving whole service groups into additional VMs rather than splitting the physical host into a cluster.

## Goals / Non-Goals

**Goals:**

- Establish the host as a declarative microVM substrate rather than the main application runtime.
- Define a first-stage VM topology with one `storage-vm` and one `media-vm`.
- Preserve media-stack file semantics needed for downloader and servarr workflows by presenting a unified data root inside `media-vm`.
- Allow LAN clients to access NAS shares and browse media files through the `storage-vm`.
- Separate large shared data from VM-private application state so service groups can be migrated more cleanly later.
- Keep the first-stage design small enough to implement and operate on a single machine.

**Non-Goals:**

- Supporting internet exposure, WAN ingress, or public TLS in the first stage.
- Defining future miscellaneous service VMs such as bots or experimental applications.
- Building a generalized orchestration framework for arbitrary VM or container types.
- Solving multi-host scheduling, clustering, or distributed storage.

## Decisions

### 1. The host acts as infrastructure substrate only

The host will own physical storage mounts, microVM runtime integration, and VM networking. It will not directly host the NAS protocols or the media application stack.

Rationale:
- This keeps the host aligned with the desired "VMs are the service boundary" model.
- It avoids mixing infrastructure concerns with application concerns on the same layer.

Alternatives considered:
- Run SMB/NFS on the host and only place applications in VMs. Rejected because it weakens the VM boundary and produces an inconsistent service model.

### 2. First stage uses two service-group VMs

The initial topology will include:
- `storage-vm` for SMB and NFS exports
- `media-vm` for Jellyfin and media automation containers

Rationale:
- These two groups have distinct responsibilities and failure domains.
- Splitting them improves clarity without fragmenting the system into many tiny VMs with unnecessary RAM overhead.

Alternatives considered:
- Put all services into one VM. Rejected because it collapses protocol and application boundaries.
- Create one VM per service. Rejected because it increases operational overhead and reserved memory with little first-stage benefit.

### 3. Use `qemu` as the initial microVM hypervisor

The first stage should assume `qemu` as the hypervisor for microVMs.

Rationale:
- The design depends on directory sharing between host and VMs.
- `microvm.nix` documents stronger support for directory-sharing workflows with `qemu` than with alternative hypervisors that have missing or weaker `9p`/`virtiofs` support.

Alternatives considered:
- Firecracker or other hypervisors. Rejected for the first stage because host-directory sharing is a core requirement and support is more constrained.

### 4. Host-owned data disk shared directly into both VMs

The data disk remains mounted on the host and selected directories are shared into both VMs. `storage-vm` and `media-vm` do not exchange media data over NFS between themselves.

Rationale:
- This avoids turning single-machine local I/O into network I/O between VMs.
- It reduces failure modes and keeps data-path debugging tractable.
- It allows both VMs to operate on the same canonical host-owned directory tree.

Alternatives considered:
- Make `storage-vm` the owner of the disk and have `media-vm` mount over NFS. Rejected because it adds protocol complexity and risks breaking media workflow assumptions.

### 4a. The system disk uses btrfs subvolumes while the data disk remains ext4

The host operating-system disk should use btrfs with separate subvolumes for `/`, `/nix`, and `/var/log`. `/boot` should remain a FAT32 EFI system partition. The dedicated bulk-data disk should continue to use ext4 and remain mounted separately at `/srv/data`.

Rationale:
- The user wants btrfs primarily for transparent compression on operating-system paths such as `/nix`.
- Separating `/var/log` from the root subvolume preserves a clearer boundary between declarative system state and continuously changing runtime logs.
- Keeping the bulk-data disk on ext4 preserves the simpler and already-established semantics for shared media and NAS data.

Alternatives considered:
- Use ext4 for both the system disk and the data disk. Rejected because it gives up btrfs compression on host system paths.
- Move the dedicated bulk-data disk to btrfs as well. Rejected for the first stage because the immediate goal is system-disk compression, not changing the data-disk semantics that the VM-sharing model already depends on.

### 5. `media-vm` receives a unified data root

`media-vm` should see downloads, media libraries, and any shared media-adjacent paths beneath one shared root such as `/data`, not as separate unrelated mounts.

Rationale:
- Servarr workflows rely on consistent filesystem semantics between downloads and final media locations.
- A single shared root minimizes path confusion across containers.

Alternatives considered:
- Separate downloads and media into different shares mounted independently in the VM. Rejected because it risks breaking efficient moves, hardlinks, and operator understanding.

### 6. Large shared data and VM-private application state are separated

Bulk data such as `/downloads`, `/media`, and `/shares` should live on the host-owned data disk and be shared into VMs. VM-private application state should use VM-owned persistent storage where practical.

Rationale:
- This keeps large shared data stable and directly accessible.
- It reduces leakage of application-specific state into the host filesystem.
- It makes a service-group VM easier to reason about and eventually migrate.

Alternatives considered:
- Store all application state directly in host-shared directories. Rejected because it blurs ownership and creates host-level sprawl.

### 7. `storage-vm` exports user shares read-write and media read-only by default

`storage-vm` should expose general-purpose shared directories for LAN clients with read-write access according to share policy. Media directories should be exportable for browsing and playback, but read-only by default.

Rationale:
- Media files need to be accessible to external clients.
- The media automation stack should remain the primary writer to the media library.
- This avoids concurrent human and automation writes into the same curated library tree.

Alternatives considered:
- Make media shares read-write to LAN clients. Rejected for the first stage due to collision risk with media automation workflows.

## Risks / Trade-offs

- Exporting host-shared directories from `storage-vm` over SMB/NFS may surface permission or file-semantic edge cases. -> Validate protocol behavior with representative media and share workflows before broadening scope.
- VM-private application state increases the number of persistence mechanisms in the system. -> Keep the split simple: shared bulk data on the host, application state private only where it materially improves ownership.
- Two VMs introduce more moving parts than a host-only setup. -> Keep the first-stage VM set intentionally small and avoid per-service microVM fragmentation.
- Read-only media exports may be less convenient for manual library curation. -> Provide a separate writable inbox or user shares path for manual ingestion instead of writing directly into curated media roots.

## Migration Plan

1. Establish the host storage layout and microVM substrate.
2. Create `storage-vm` with share exports for user-facing directories and optional read-only media browsing.
3. Create `media-vm` with a unified shared data root and VM-private application state.
4. Deploy media containers inside `media-vm` and validate downloader, import, and playback workflows.
5. Add future service-group VMs only after the first-stage storage and media patterns are proven.

Rollback strategy:
- Disable the affected VM definition while preserving host-owned shared data.
- Because the host remains the owner of the canonical data layout, VM rollback should not require moving the bulk data.

## Open Questions

- Which container runtime inside each microVM best matches the desired declarative workflow.
- Whether `storage-vm` should export the full media tree or only selected subtrees such as `movies` and `tv`.
- Whether a separate writable `inbox` directory is needed in the first stage for human-uploaded media.
