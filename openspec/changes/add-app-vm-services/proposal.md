## Why

The current homelab design cleanly separates NAS and media workloads, but it has no dedicated service boundary for general-purpose application workloads such as RSSHub. Adding those services to `media-vm` would mix unrelated responsibilities, data models, and operational concerns inside the same VM.

## What Changes

- Introduce a dedicated `app-vm` service-group microVM for general-purpose application services.
- Define `app-vm` as the first home for RSSHub and as the default landing zone for future lightweight HTTP- or worker-style applications that do not belong to NAS or media workflows.
- Define the persistence model for `app-vm` around VM-private application state rather than the shared bulk-data root by default.
- Define the networking model for `app-vm`, including host-level access to selected application ports while preserving the host's role as infrastructure substrate.
- Keep `storage-vm` and `media-vm` focused on their existing service boundaries instead of expanding them into a catch-all application tier.

## Capabilities

### New Capabilities
- `app-vm-services`: Dedicated microVM for RSSHub and future general-purpose application services, with VM-private state and application-oriented networking.

### Modified Capabilities
- `homelab-host-foundation`: The host must support an additional service-group microVM and expose the networking/runtime attachments required for application services.

## Impact

- Adds a third service-group VM to the current homelab topology.
- Introduces a new application-service boundary that future non-media services can reuse.
- Expands host microVM orchestration and port-exposure responsibilities.
- Creates a new persistence and networking pattern distinct from the shared-media model used by `media-vm`.
