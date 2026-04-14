# Router VM Mihomo Design

Date: 2026-04-14

## Summary

This document defines how the homelab adds a dedicated `router-vm` that provides route-node and ordinary proxy capabilities using `mihomo`.

The chosen direction is:
- Add a new `router-vm` as a first-class microVM alongside `storage-vm`, `media-vm`, and `app-vm`.
- Run `mihomo` inside `router-vm`, not on the host and not in an OpenWrt container.
- Use `TUN + fake-ip` as the first implementation target.
- Keep the real `mihomo` runtime configuration outside Git in a host-local directory.
- Mount that host-local directory into `router-vm` and let `mihomo` consume it directly.
- Allow `router-vm` to boot even when the local `mihomo` config file is absent.

## Goals

- Add a dedicated route/proxy VM without collapsing network responsibilities back onto the host.
- Provide a route-node workflow where opted-in clients can set `router-vm` as their default gateway.
- Provide ordinary `http` and `socks5` proxy endpoints for clients that do not want gateway-based routing.
- Reproduce an OpenClash-like usage model with `mihomo` on NixOS.
- Preserve the repository's existing microVM service-boundary pattern.
- Avoid storing subscription URLs or provider credentials in Git.

## Non-Goals

- Replacing the main router.
- Building an OpenWrt-based management UI.
- Forcing the entire LAN to use the proxy node by default.
- Designing a full secret-management layer for proxy subscriptions in this iteration.
- Supporting both `mihomo` and `sing-box` in the first implementation.

## Current Context

The repository already defines:
- A host bridge network on `br0`.
- Static LAN addresses for the host and the current service-group VMs.
- A microVM host substrate that already runs dedicated workload VMs.

The repository does not currently define:
- A dedicated router/proxy VM.
- A proxy-core service such as `mihomo`.
- A route-node workflow for clients that want to use a VM as their gateway.

## Chosen Approach

The system will add a dedicated `router-vm` that runs `mihomo` in TUN mode with `fake-ip` DNS behavior.

The first implementation will use a host-local config directory rather than repository-managed encrypted subscription content.

Configuration ownership and flow will be:
1. The repository defines the VM, service wiring, static IP, state paths, and startup rules.
2. The operator maintains the real `mihomo` configuration on the host filesystem.
3. The host mounts that local config directory into `router-vm`.
4. `mihomo` starts only when the expected local config file is present.
5. Clients either set `router-vm` as their default gateway or use its `http` / `socks5` proxy ports directly.

This approach is preferred over an OpenWrt container because network ownership and debugging remain much cleaner when the route node is a dedicated VM with a clear boundary.

It is preferred over `sing-box` for the first implementation because the desired user experience is close to OpenClash, especially around `TUN`, `fake-ip`, and subscription/provider workflows.

## Architecture

### Execution Boundary

`router-vm` is a dedicated network-function VM.

Implications:
- The host remains responsible for bridge networking and microVM lifecycle.
- `router-vm` owns route-node and proxy-core behavior.
- Existing VMs keep their current workload responsibilities.
- Proxy routing logic is isolated from the host and from unrelated application VMs.

This keeps the homelab aligned with its current service-group VM model instead of introducing a container that shares the host network namespace.

### Repository Layout

The repository should introduce a structure equivalent to:

- `vms/router-vm.nix`
- `modules/router-vm/identity.nix`
- `modules/router-vm/microvm.nix`
- `modules/router-vm/networking.nix`
- `modules/router-vm/mihomo.nix`
- `modules/router-vm/state.nix`

Shared constants should be added to [`lib/homelab-config.nix`](../../../../lib/homelab-config.nix), including:
- `routerVm.address`
- `routerVm.memory`
- `routerVm.vcpu`
- `routerVm.stateVolume`
- `routerVm.configHostPath`
- `routerVm.configGuestPath`

The host microVM registry should be extended in [`modules/host/microvm-host.nix`](../../../../modules/host/microvm-host.nix).

### Network Topology

`router-vm` should join the existing `br0` LAN bridge like the other VMs.

Planned addressing:
- Host: `192.168.31.210`
- `storage-vm`: `192.168.31.211`
- `media-vm`: `192.168.31.212`
- `app-vm`: `192.168.31.213`
- `router-vm`: `192.168.31.214`

`router-vm` is a single-arm route node, not a dual-interface WAN/LAN router.

Implications:
- The main router at `192.168.31.1` remains the actual upstream gateway.
- Clients must opt in by pointing their default gateway to `192.168.31.214`.
- No WAN-side interface split is required inside `router-vm`.

### Service Model

`router-vm` should provide two consumption models:

1. Route-node mode
- A client sets its default gateway to `192.168.31.214`.
- `router-vm` forwards and classifies the client's traffic through `mihomo`.

2. Ordinary proxy mode
- A client uses `http` or `socks5` directly against `router-vm`.
- This avoids changing the client's default gateway.

The first implementation should support both modes because they share the same proxy core and make the VM immediately useful in multiple ways.

## Mihomo Design

### Core Runtime Mode

The proxy core should be `mihomo` running with:
- `TUN`
- `fake-ip`
- ordinary `http` / `socks5` inbound listeners

Rationale:
- `TUN` provides a cleaner traffic-capture model than starting with manual `TPROXY` or `REDIRECT` rules.
- `fake-ip` provides the OpenClash-like DNS behavior the operator wants.
- ordinary proxy listeners make the VM useful even before any client switches its default gateway.

### Routing Behavior

`router-vm` should enable:
- IPv4 forwarding
- the minimum firewall and forwarding rules required for a route-node workflow
- the network prerequisites that allow `mihomo` TUN mode to receive and classify forwarded traffic

The exact low-level packet-steering details belong in the implementation plan, but the design intent is:
- Linux forwards traffic through the VM
- `mihomo` TUN and DNS logic perform classification
- traffic is then sent either directly to the upstream gateway or through a configured proxy path

### Runtime Configuration Source

The real `mihomo` configuration should live outside Git in a host-local directory.

Recommended paths:
- Host: `/srv/data/router/mihomo`
- Guest mountpoint: `/var/lib/router-vm/mihomo-config`
- Main config file: `/var/lib/router-vm/mihomo-config/config.yaml`

This local config file may include:
- provider URLs
- provider credentials
- proxy groups
- rules
- DNS behavior

The repository should not store that real config content in this iteration.

## Bootstrap and Startup Behavior

### Config-Absent State

Missing local `mihomo` config must be treated as valid bootstrap state.

Expected behavior:
- Host deployment succeeds.
- `router-vm` deployment succeeds.
- `router-vm` receives its LAN identity and boots normally.
- `mihomo` is skipped or remains inactive because the runtime config file is missing.

The intended model is "VM up, proxy service inactive until config exists," not "missing config breaks deployment."

### Config-Present State

When the expected config file exists on the host:
- the host mount is present inside `router-vm`
- `mihomo` starts automatically
- `router-vm` becomes usable as both a route node and a normal proxy endpoint

### Invalid Config

If the local config file exists but is invalid:
- `router-vm` still boots
- `mihomo` fails to start or enters an error state
- the failure must be diagnosable from `router-vm` service logs

This must be treated as application/runtime configuration failure, not VM bootstrap failure.

## Operations

### Operator Workflow

The intended operator workflow is:
1. Deploy the repository and create `router-vm`.
2. Confirm that `router-vm` is reachable on `192.168.31.214`.
3. Place a real `mihomo` config at `/srv/data/router/mihomo/config.yaml` on the host.
4. Restart or redeploy `router-vm`.
5. Point a test client at `192.168.31.214` either as gateway or proxy endpoint.

No manual edits inside the VM should be required for ordinary operation.

### Config Persistence

Because the real config is host-local and not in Git:
- rebuilds should not destroy it
- host reinstall without preserving `/srv/data` would require recreating it
- the mounted config path becomes part of the operational recovery model

This is an accepted tradeoff for the first iteration.

## Tradeoffs and Rationale

### Why Not OpenWrt In A Host Container

This is rejected because:
- network ownership would become ambiguous between host, container namespace, and OpenWrt
- debugging packet flow would be harder
- the architecture would diverge from the repository's existing VM-boundary model

### Why Not OpenWrt As The First VM Implementation

OpenWrt is workable, but it is rejected for the first implementation because:
- the repository is already NixOS-based
- `mihomo` can run directly in a NixOS VM
- the operator does not currently need the OpenWrt UI or package ecosystem to justify the extra boundary

### Why Host-Local Config Instead Of Repository Secrets

This is accepted for the first iteration because:
- the operator explicitly wants local files rather than a secret-management flow
- subscription URLs and provider tokens are operator-managed runtime data
- it reduces time-to-first-working-route-node

The downside is reduced reproducibility, which is acceptable for the first iteration.

## Future Extension

The same `router-vm` can later be extended to support:
- repository-managed secret-backed provider URLs
- `sing-box` as an alternative runtime
- more advanced policy-routing behavior
- DNS service for opted-in clients
- expanded observability and health checks

Those items are deferred until the first `mihomo` route-node workflow is working.

## Acceptance Criteria

- The repository can deploy a dedicated `router-vm` with fixed LAN identity `192.168.31.214`.
- `router-vm` can boot successfully even when the local `mihomo` config file is absent.
- A host-local `mihomo` config directory can be mounted into `router-vm`.
- `mihomo` can start from the mounted config when `config.yaml` exists.
- `router-vm` can act as a default-gateway target for opted-in clients.
- `router-vm` can expose ordinary `http` and `socks5` proxy entrypoints.
- The first implementation stays within the existing NixOS microVM architecture and does not require OpenWrt.
