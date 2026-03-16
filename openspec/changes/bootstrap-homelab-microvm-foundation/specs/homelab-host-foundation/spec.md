## ADDED Requirements

### Requirement: Host provides microVM substrate
The system SHALL define a single NixOS host that mounts the system disk and a separate bulk-data disk, provides the `microvm.nix` runtime, and supplies the networking and storage attachments required by service-group microVMs.

#### Scenario: Host prepares first-stage infrastructure
- **WHEN** the homelab host is evaluated for the first-stage deployment
- **THEN** it includes the virtualization and networking capabilities needed to run `storage-vm` and `media-vm`

#### Scenario: Host remains outside the application boundary
- **WHEN** first-stage workloads are assigned to execution environments
- **THEN** SMB, NFS, Jellyfin, and the media automation stack are assigned to microVMs rather than running directly on the host

### Requirement: Host separates system and bulk data storage
The system SHALL keep operating-system storage separate from bulk homelab data storage so that service data, downloads, and media libraries do not depend on the system disk layout.

#### Scenario: Host provisions bulk data paths
- **WHEN** persistent homelab data is defined
- **THEN** the host mounts a dedicated data disk and exposes the required persistent root for shared data

#### Scenario: Host preserves shared data during VM lifecycle changes
- **WHEN** a first-stage microVM is recreated, disabled, or rolled back
- **THEN** the bulk data on the dedicated data disk remains outside the VM root filesystem lifecycle
