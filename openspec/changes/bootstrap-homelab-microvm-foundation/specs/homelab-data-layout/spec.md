## ADDED Requirements

### Requirement: Homelab defines a canonical shared data layout
The system SHALL define a canonical persistent data layout for first-stage homelab storage that distinguishes downloads, curated media, general-purpose shares, and application-owned state.

#### Scenario: Operator inspects persistent homelab data
- **WHEN** the first-stage data disk is mounted on the host
- **THEN** the directory tree clearly separates download content, curated media, user-facing shares, and application state

### Requirement: Service groups consume shared data through stable paths
The system SHALL expose stable path contracts between host, microVMs, and containers so that each service group can mount the data it needs without ambiguous remapping.

#### Scenario: Media VM consumes shared data
- **WHEN** `media-vm` mounts the host-owned shared data
- **THEN** its containers inherit consistent paths for downloads and curated media

#### Scenario: Storage VM consumes shared data
- **WHEN** `storage-vm` mounts the host-owned shared data
- **THEN** it can export user shares and selected media directories without redefining the canonical storage layout

### Requirement: Curated media and user-ingest paths remain distinct
The system SHALL keep curated media directories distinct from writable user-ingest or general-purpose share paths so external writes do not directly modify the managed media library by default.

#### Scenario: User uploads non-curated content
- **WHEN** a LAN client writes files intended for later organization
- **THEN** those files are written to a writable ingest or user-share path rather than directly into the curated media library

#### Scenario: Media automation updates curated library
- **WHEN** the media automation stack imports or reorganizes content
- **THEN** it writes to the curated media library without requiring arbitrary external clients to share the same write privileges
