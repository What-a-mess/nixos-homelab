## ADDED Requirements

### Requirement: Media stack runs inside a dedicated microVM
The system SHALL provide a dedicated `media-vm` that hosts the first-stage media stack and keeps it isolated from the host and from `storage-vm`.

#### Scenario: First-stage media services are deployed
- **WHEN** the homelab media capability is enabled
- **THEN** Jellyfin, Sonarr, Radarr, Prowlarr, and the downloader run inside `media-vm`

### Requirement: Media services run as containers inside the media VM
The system SHALL run the first-stage media services as containers within `media-vm` rather than as directly installed host services.

#### Scenario: Media VM provisions its workloads
- **WHEN** `media-vm` is configured for the first stage
- **THEN** the media services are defined as containerized workloads inside the VM

### Requirement: Media VM receives a unified shared data root
The system SHALL present downloads and media libraries inside `media-vm` beneath one shared root so the media workflow operates on a consistent filesystem tree.

#### Scenario: Downloader writes files for import
- **WHEN** the downloader stores completed content
- **THEN** Sonarr and Radarr can access both the download location and the final media library location beneath the same VM-visible data root

#### Scenario: Jellyfin scans curated media
- **WHEN** Jellyfin scans libraries inside `media-vm`
- **THEN** it reads the curated media tree from the same shared data root used by the media automation stack

### Requirement: Media VM keeps application state persistent
The system SHALL persist media-application state independently from the VM root filesystem so that service configuration and metadata survive VM recreation.

#### Scenario: Media VM is recreated
- **WHEN** `media-vm` is rebuilt or replaced
- **THEN** the persistent state for Jellyfin and the media automation stack remains recoverable without reconstructing the full application configuration from scratch
