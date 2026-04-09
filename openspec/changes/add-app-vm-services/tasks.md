## 1. Host foundation updates

- [x] 1.1 Extend the host microVM substrate to declare and start `app-vm`.
- [x] 1.2 Define host-level port exposure and firewall rules for `app-vm` application services.

## 2. App VM foundation

- [x] 2.1 Add the declarative `app-vm` entrypoint and module structure.
- [x] 2.2 Define `app-vm` identity, networking, and VM-private persistent state.
- [x] 2.3 Define the initial application runtime model inside `app-vm`.

## 3. RSSHub deployment

- [x] 3.1 Add RSSHub as the first application workload inside `app-vm`.
- [x] 3.2 Add any tightly coupled helper services or runtime dependencies that RSSHub requires inside `app-vm`.
- [x] 3.3 Configure RSSHub persistence, service ports, and any required environment wiring.

## 4. Validation

- [ ] 4.1 Verify that `app-vm` boots successfully and preserves its private state across recreation.
- [ ] 4.2 Verify that the host can reach RSSHub through the configured forwarded port.
- [x] 4.3 Document any application-tier follow-up constraints, such as ingress, helper services, or criteria for splitting workloads out of `app-vm`.
