# Edge Caddy and mTLS Design

## Goal

Replace the earlier host edge design based on Nginx with a host-level Caddy ingress that:

- serves as the single public entrypoint for homelab services
- routes requests to the correct VM backend by hostname
- uses mutual TLS (`mTLS`) for all currently public services
- keeps a path open for future services that may not require `mTLS`
- continues to support IPv6-only public ingress
- keeps certificate material out of Git

This design supersedes the earlier host-edge Nginx ingress direction for public service access.

## Constraints

- The homelab host has public IPv6 reachability and no public IPv4 requirement.
- The user is willing to use an explicit public HTTPS port instead of `443`.
- DNS is managed by Alibaba Cloud DNS.
- Public ingress is centralized on the host, not distributed across VMs.
- All currently public services should require `mTLS`.
- Future services may opt out of `mTLS`, so the design must support per-service policy.
- The user accepts that domain names and ports may be kept in plain configuration if needed.

## Recommended Architecture

The host runs a single Caddy instance that:

- listens on one external HTTPS port
- matches requests by hostname
- enforces `mTLS` per site
- reverse proxies to fixed VM backends on the LAN

The VMs keep their current service roles:

- `app-vm` for RSSHub
- `media-vm` for media services
- `router-vm` for routing or proxy-related management endpoints
- `storage-vm` remains outside the public HTTP ingress path

The host is the only public TLS and authentication boundary.

## Certificate Model

There are three separate certificate roles in this design.

### 1. Server Certificate

This certificate is presented by Caddy to clients.

Purpose:

- prove the identity of the host edge endpoint
- secure the TLS session

It may continue to be issued through ACME with Alibaba Cloud DNS `DNS-01`, because the host still does not need to expose `80` or `443`.

### 2. Client CA

This is a private CA used only to sign client certificates for trusted devices.

Purpose:

- define the set of devices that Caddy should trust for `mTLS`

This CA is sensitive material and must never be committed to Git.

### 3. Client Device Certificates

Each trusted device receives its own client certificate.

Examples:

- `wamess-macbook`
- `wamess-iphone`
- `wamess-ipad`

These certificates are installed on devices and presented during the TLS handshake.

This enables per-device lifecycle management:

- add a new device by issuing a new cert
- replace a lost device certificate
- revoke or rotate a single device without rebuilding the whole edge layer

## File and Storage Model

Public structure can remain in Git. Secret certificate material must remain on the host.

Recommended host-local layout:

- `/srv/data/edge/caddy/`
- `/srv/data/edge/caddy/Caddyfile`
- `/srv/data/edge/pki/server/`
- `/srv/data/edge/pki/client-ca/`
- `/srv/data/edge/pki/clients/`

Suggested responsibilities:

- `/srv/data/edge/caddy/Caddyfile`
  Runtime Caddy configuration
- `/srv/data/edge/pki/server/`
  Server certificate and key material used by Caddy
- `/srv/data/edge/pki/client-ca/`
  Client CA certificate and private key
- `/srv/data/edge/pki/clients/`
  Exported client bundles such as `.p12` files for user devices

None of these materials should be stored in Git.

## Public Configuration Model

Shared homelab configuration in Git should define:

- public edge port
- public service host prefixes
- backend VM address and port
- whether each public service requires `mTLS`

This keeps the structure explicit and reviewable while leaving certificate materials on the host.

Recommended shape in shared config:

- service name
- hostname prefix
- backend host
- backend port
- `requireMtls = true`

All current public services should set `requireMtls = true`.

Future services can opt out by setting `requireMtls = false` without requiring an edge-layer redesign.

## Caddy Routing Model

The host Caddy instance:

- listens on a single configured HTTPS port
- uses hostname-based routing
- enforces `mTLS` for sites marked `requireMtls = true`
- reverse proxies to the correct VM backend

Example routes:

- `rsshub.<domain>` -> `192.168.31.213:1200`
- `jellyfin.<domain>` -> `192.168.31.212:8096`
- `sonarr.<domain>` -> `192.168.31.212:8989`
- `radarr.<domain>` -> `192.168.31.212:7878`
- `prowlarr.<domain>` -> `192.168.31.212:9696`
- `qb.<domain>` -> `192.168.31.212:8080`
- `router.<domain>` -> `192.168.31.214:9090`

For services with `requireMtls = true`, the corresponding Caddy site must use:

- trusted client CA material from the host-local PKI directory
- `require_and_verify` style client authentication

If a future service sets `requireMtls = false`, the same routing layer can still serve it without client cert enforcement.

## DDNS Design

The host continues to manage Alibaba Cloud DNS updates.

Recommended public DNS model:

- wildcard `AAAA` record for `*.${domain}`
- optional apex `AAAA` record for `${domain}`

Both records point to the host public IPv6 address.

DDNS remains independent of `mTLS`:

- DDNS decides where traffic goes
- Caddy decides whether a client is trusted

## First Deployment Flow

1. Deploy the host and VMs.
2. Create the host-local edge directories under `/srv/data/edge/`.
3. Configure DDNS for wildcard and optional apex `AAAA` records.
4. Provision or issue the server certificate for Caddy.
5. Generate the client CA.
6. Generate at least one client device certificate.
7. Install the client CA trust material into the host-local Caddy PKI paths.
8. Install the device certificate bundle on the user device.
9. Start or reload Caddy.
10. Verify that the public hostname is reachable only with a valid client certificate.

## Bootstrap and Failure Behavior

The host and VMs must remain bootable even if the edge PKI material is incomplete.

### No edge PKI files yet

- host boots normally
- VMs boot normally
- public ingress may be unavailable
- Caddy may stay disabled or fail closed, depending on implementation choice

### Server certificate missing

- Caddy should not serve public sites
- host and VMs remain healthy

### Client CA missing

- `mTLS` sites should not become anonymously accessible
- Caddy should fail closed for those sites

### Client certificate missing on device

- TLS handshake or authorization fails
- request does not reach backend services

### DDNS lag or DNS propagation delay

- domain may temporarily resolve incorrectly or not at all
- internal routing model remains valid

The edge layer should fail closed for public access, but never block host or VM boot.

## Security Notes

This design improves access control substantially compared with hiding domain names or ports.

Its real security boundary is:

- possession of a valid client certificate signed by the trusted client CA

This is stronger than:

- IP allowlists for unstable client IPs
- basic auth alone
- keeping ports obscure

Residual security requirements still matter:

- protect the client CA private key carefully
- rotate compromised device certificates
- keep Caddy and backend services patched
- keep only required public services enabled

## Operations

Operators need procedures for:

- generating the client CA
- issuing per-device client certificates
- exporting `.p12` bundles for device installation
- rotating or revoking device certificates
- reloading Caddy after PKI updates
- verifying that `mTLS` is enforced on every intended public site

Operational checks should include:

- Caddy service status
- listener status on the public edge port
- successful access with a valid client certificate
- failed access without a client certificate
- hostname routing to the correct backend

## Non-Goals

This design does not include:

- exposing raw backend service ports publicly
- removing DDNS support
- moving ingress responsibility into the VMs
- building a private-mesh-only access path such as Tailscale
- replacing backend application authentication

## Implementation Notes

The implementation should add a host edge layer built around Caddy instead of Nginx.

The edge layer should:

- generate or load a Caddy configuration from shared homelab service topology
- reference host-local PKI files
- support a per-service `requireMtls` switch
- preserve the current VM backend boundaries

Any remaining Nginx-specific ingress design work should be treated as superseded by this Caddy-based design.
