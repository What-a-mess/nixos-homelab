## Context

The current homelab topology has two service-group microVMs: `storage-vm` for NAS protocols and `media-vm` for Jellyfin plus the media automation stack. That split works because each VM has a clear responsibility, data model, and failure domain.

RSSHub introduces a different class of workload. It is an application-facing HTTP service with its own runtime state, dependency profile, and future expansion path. Treating it as part of `media-vm` would collapse the existing service boundaries and make the media stack a catch-all runtime for unrelated applications.

The repository already assumes that the host is only a substrate for disks, VM runtime, and networking. The clean extension of that model is to add a third service-group VM for general-purpose applications rather than placing those services on the host or mixing them into `media-vm`.

## Goals / Non-Goals

**Goals:**

- Introduce a dedicated `app-vm` for general-purpose application services such as RSSHub.
- Keep `storage-vm` and `media-vm` focused on NAS and media workloads respectively.
- Define a persistence pattern for application services that defaults to VM-private state rather than the shared bulk-data tree.
- Define a host-to-`app-vm` networking pattern that matches the existing microVM architecture.
- Create an extensible service-group boundary for future lightweight HTTP and worker services.

**Non-Goals:**

- Defining internet exposure, WAN ingress, or public TLS for the new application services.
- Creating one microVM per application from the outset.
- Refactoring the existing `media-vm` service model in the same change.
- Building a generalized orchestration framework for arbitrary service scheduling across multiple hosts.

## Decisions

### 1. Introduce a shared `app-vm` service group instead of a dedicated `rsshub-vm`

The system should add one `app-vm` that serves as the default execution boundary for RSSHub and similar future application services.

Rationale:
- RSSHub is the first example of a broader application-service category, not a one-off exception.
- A shared application VM avoids VM sprawl while preserving a clean boundary from the media and NAS domains.
- This keeps future application additions incremental: new services can be evaluated against the `app-vm` boundary first and only split out if they develop distinct operational needs.

Alternatives considered:
- Put RSSHub into `media-vm`. Rejected because it mixes unrelated responsibilities and state models.
- Create a dedicated `rsshub-vm`. Rejected for the first application because it optimizes for isolation before the shape of the broader application tier is known.

### 2. `app-vm` defaults to VM-private persistent state

Application-service state should live on a VM-private persistent volume by default. `app-vm` should not receive the host bulk-data root unless a specific application has a justified shared-storage requirement.

Rationale:
- RSSHub and similar services are primarily HTTP applications and do not depend on the shared media filesystem semantics that drove the `media-vm` design.
- Private state keeps application internals out of the host data layout and reduces accidental coupling to `/srv/data`.
- This preserves the shared data tree for workloads that actually need cross-VM file access.

Alternatives considered:
- Share the entire host data root into `app-vm`. Rejected because it expands the blast radius and encourages unclear ownership of application state.
- Store all application state directly on the host. Rejected because it breaks the “VM is the service boundary” rule.

### 3. Reuse the existing host port-forwarding model for the first application tier

`app-vm` should use the same host-mediated exposure model as the current VMs: services bind inside the VM, and the host forwards only the selected application ports.

Rationale:
- It fits the existing single-host, LAN-first architecture.
- It keeps the host as the networking choke point without requiring a new ingress layer immediately.
- It allows RSSHub to be introduced with a minimal change in operational shape.

Alternatives considered:
- Give `app-vm` a different network model such as a bridge-only design. Rejected for the initial application tier because it complicates the current topology without a clear first-stage need.
- Introduce a reverse-proxy VM in the same change. Rejected because it expands scope beyond the current application-service boundary problem.

### 4. Keep the application runtime model local to `app-vm`

The first version of `app-vm` should encapsulate RSSHub and any tightly coupled helper services within the VM, using the same declarative service style already used elsewhere in the repository.

Rationale:
- RSSHub may eventually require companion components such as cache or browser automation services.
- Keeping these dependencies inside `app-vm` preserves a coherent failure domain and deployment unit.
- This leaves room to refine “containers versus native services” later without changing the higher-level VM boundary.

Alternatives considered:
- Run helper services on the host. Rejected because it leaks application concerns onto the substrate.
- Solve the runtime-model question globally before adding `app-vm`. Rejected because the architectural boundary can be defined now without blocking on that narrower implementation choice.

## Risks / Trade-offs

- `app-vm` may become a miscellaneous bucket for unrelated services. -> Define clear criteria for what belongs in `app-vm` and split out only when a service has materially different security, performance, or exposure needs.
- Adding a third VM increases memory overhead on a single machine. -> Keep `app-vm` lightweight and avoid over-provisioning until the service set grows.
- RSSHub may need sidecar components that complicate the first implementation. -> Keep companion services inside `app-vm` and treat them as part of one application-service boundary.
- The host port-forwarding model may become awkward if many application services accumulate. -> Preserve the option to introduce a dedicated ingress layer in a later change.

## Migration Plan

1. Extend the host foundation so it can instantiate and expose an `app-vm`.
2. Define `app-vm` identity, networking, and private persistent state.
3. Add RSSHub as the first application workload inside `app-vm`.
4. Validate that the host can reach RSSHub through the exposed application port and that application state survives VM recreation.
5. Add future application services to `app-vm` only if they match the same boundary assumptions.

Rollback strategy:
- Disable the `app-vm` definition and remove its host port exposure.
- Preserve the VM-private state volume so the application tier can be reintroduced without rebuilding all state from scratch.

## Open Questions

- Whether RSSHub should be the only initial workload in `app-vm` or whether its helper services should be modeled as first-class colocated components from day one.
- Which application port allocation scheme should be used for `app-vm` as more services are added.
- When the application tier should graduate to a dedicated reverse-proxy or ingress boundary instead of direct host port forwarding.
