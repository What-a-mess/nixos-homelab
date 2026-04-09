## MODIFIED Requirements

### Requirement: Host provides microVM substrate
The system SHALL define a single NixOS host that mounts the system disk and a separate bulk-data disk, provides the `microvm.nix` runtime, and supplies the networking and storage attachments required by service-group microVMs.

#### Scenario: Host prepares first-stage infrastructure
- **WHEN** the homelab host is evaluated for the first-stage deployment
- **THEN** it includes the virtualization and networking capabilities needed to run `storage-vm`, `media-vm`, and `app-vm`

#### Scenario: Host remains outside the application boundary
- **WHEN** homelab workloads are assigned to execution environments
- **THEN** SMB, NFS, Jellyfin, the media automation stack, RSSHub, and similar application services are assigned to microVMs rather than running directly on the host
