## ADDED Requirements

### Requirement: Homelab provides a dedicated application-service VM
The system SHALL define an `app-vm` service-group microVM that hosts RSSHub and future general-purpose application services without colocating them in `media-vm` or on the host.

#### Scenario: Operator assigns RSSHub to an execution boundary
- **WHEN** RSSHub is introduced into the homelab
- **THEN** it is deployed within `app-vm` rather than `media-vm`, `storage-vm`, or the host directly

#### Scenario: Operator evaluates a future lightweight application service
- **WHEN** an application service does not require NAS protocol ownership or media-library workflow semantics
- **THEN** `app-vm` is the default service boundary for that workload

### Requirement: Application services default to VM-private persistent state
The system SHALL persist `app-vm` application state on VM-private storage by default and SHALL NOT require mounting the host bulk-data root into `app-vm` unless a specific shared-data need has been declared.

#### Scenario: RSSHub stores runtime data
- **WHEN** RSSHub writes configuration, cache, or other persistent runtime state
- **THEN** that state is stored on `app-vm` private persistence rather than the host shared data root

#### Scenario: An application service has no shared-data requirement
- **WHEN** a service is added to `app-vm`
- **THEN** it receives only the storage attachments required for its own runtime state and not the full shared bulk-data tree by default

### Requirement: Application services are reachable through host-managed port exposure
The system SHALL expose selected `app-vm` application ports through the host-managed microVM networking layer.

#### Scenario: LAN client connects to RSSHub
- **WHEN** a client connects to the configured RSSHub port on the homelab host
- **THEN** the host forwards that connection to the RSSHub service inside `app-vm`

#### Scenario: Non-exposed services remain internal
- **WHEN** an `app-vm` workload does not have an explicitly configured host-facing port
- **THEN** it is not automatically reachable through the host networking surface
