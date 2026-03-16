## ADDED Requirements

### Requirement: Storage VM provides LAN file-sharing protocols
The system SHALL provide a dedicated `storage-vm` that exports file-sharing services for LAN clients using SMB and NFS.

#### Scenario: LAN client accesses NAS protocols
- **WHEN** an authorized LAN client requests a configured share
- **THEN** the request is served by `storage-vm` rather than by the host or `media-vm`

### Requirement: Storage VM exports user shares separately from curated media
The system SHALL treat general-purpose user shares and curated media libraries as distinct exported directory classes with independently configurable access policies.

#### Scenario: User accesses writable general-purpose share
- **WHEN** a LAN client mounts a configured general-purpose share
- **THEN** the share policy MAY permit read-write access without granting write access to curated media directories

#### Scenario: User accesses curated media export
- **WHEN** a LAN client mounts a configured media export
- **THEN** the export is distinguishable from general-purpose shares and can be configured with a more restrictive access policy

### Requirement: Storage VM supports read-only media browsing by default
The system SHALL allow curated media directories to be exported for LAN playback and browsing while defaulting those exports to read-only access.

#### Scenario: Client browses media library
- **WHEN** a LAN client opens an exported media directory
- **THEN** the client can read video files without requiring direct access to the media automation stack

#### Scenario: Client attempts to modify curated media
- **WHEN** a LAN client uses the default media export policy
- **THEN** the export denies write operations to curated media directories
