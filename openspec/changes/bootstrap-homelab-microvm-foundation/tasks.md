## 1. Host foundation

- [x] 1.1 Create the base NixOS host structure for the homelab machine and add the `microvm.nix` dependency.
- [x] 1.2 Define the host storage layout for the system disk and dedicated bulk-data disk.
- [x] 1.3 Define the canonical shared data root and its first-stage subdirectories.
- [x] 1.4 Configure the host networking and microVM substrate required by `storage-vm` and `media-vm`.

## 2. Storage VM

- [x] 2.1 Define the declarative `storage-vm` and attach the canonical shared data root.
- [x] 2.2 Configure SMB exports for general-purpose writable shares.
- [x] 2.3 Configure NFS exports for the required LAN-accessible directories.
- [x] 2.4 Configure selected media exports with read-only access by default.

## 3. Media VM

- [x] 3.1 Define the declarative `media-vm` with a unified shared data root for downloads and media.
- [x] 3.2 Add persistent VM-private state storage for Jellyfin and the media automation stack.
- [x] 3.3 Define containerized workloads for Jellyfin, Sonarr, Radarr, Prowlarr, and the downloader.
- [x] 3.4 Configure container mounts so all media services consume stable in-VM paths.

## 4. Validation

- [ ] 4.1 Verify that LAN clients can mount SMB and NFS exports from `storage-vm`.
- [ ] 4.2 Verify that the media stack can move or import content from downloads into the curated media library using the shared data root.
- [ ] 4.3 Verify that Jellyfin can read the curated media library while LAN clients can browse exported media files.
- [ ] 4.4 Document any unresolved permission or protocol edge cases discovered during validation.
