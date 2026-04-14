# Edge DDNS, Nginx, and ACME Design

## Goal

Add a host-level edge layer that:

- updates public DNS records through Alibaba Cloud DNS
- terminates TLS on the host
- routes requests to the correct VM service by hostname
- works with an IPv6-only public entrypoint
- does not require public `80` or `443`
- keeps DNS credentials, public domain names, and external port assignments out of Git

The edge layer must be bootstrap-safe. A first deployment without edge secrets must still allow the host and VMs to boot normally.

## Constraints

- The homelab host has public IPv6 reachability but no public IPv4.
- The user does not want to expose standard `80` or `443`; access will use an explicit HTTPS port.
- DNS is managed by Alibaba Cloud DNS.
- TLS issuance must therefore use ACME `DNS-01`.
- The external ingress point must be a single host-level Nginx instance.
- Existing service VMs remain the service boundaries:
  - `app-vm`
  - `media-vm`
  - `storage-vm`
  - `router-vm`
- Sensitive ingress topology should not live in Git. This includes:
  - public domain
  - external HTTPS port
  - public service hostnames
  - Alibaba Cloud DNS API credentials

## Recommended Architecture

Add a new host-level `edge` layer composed of:

- `DDNS`: update wildcard and optional apex `AAAA` records in Alibaba Cloud DNS
- `ACME`: request and renew wildcard certificates via `DNS-01`
- `Nginx`: terminate TLS and reverse proxy traffic to the correct VM backend based on hostname

The host is the only public ingress point. VMs continue to expose services only on the LAN.

## Secret Model

Use two encrypted secrets, both managed by `agenix` and decrypted on the host:

### `edge-aliyun.env.age`

Stores Alibaba Cloud DNS credentials.

Example shape:

```env
ALICLOUD_ACCESS_KEY=...
ALICLOUD_SECRET_KEY=...
```

### `edge-routing.env.age`

Stores edge topology that the user wants to keep out of Git.

Example shape:

```env
EDGE_DOMAIN=example.com
EDGE_HTTPS_PORT=28443

RSSHUB_HOST=rsshub
JELLYFIN_HOST=jellyfin
SONARR_HOST=sonarr
RADARR_HOST=radarr
PROWLARR_HOST=prowlarr
QBITTORRENT_HOST=qb
ROUTER_HOST=router
```

These secrets are decrypted on the host into runtime paths under `/run/agenix/`.

## Public Configuration Model

Git should still hold stable infrastructure structure, but not sensitive ingress naming.

Public configuration should define:

- which services are exposed through the edge layer
- their internal backends
- whether the apex domain should be managed

Sensitive configuration remains in secrets:

- public domain
- external HTTPS port
- public service hostname prefixes
- Alibaba Cloud DNS credentials

## DNS Design

Use Alibaba Cloud DNS with:

- a wildcard `AAAA` record: `*.${EDGE_DOMAIN}`
- optionally an apex `AAAA` record: `${EDGE_DOMAIN}`

Both records point to the host's public IPv6 address.

DDNS only manages these records. It does not manage per-service records.

This keeps DNS maintenance small and aligns with hostname-based routing at Nginx.

## Certificate Design

Use NixOS `security.acme` on the host with Alibaba Cloud DNS `DNS-01`.

Certificates requested:

- `*.${EDGE_DOMAIN}`
- optionally `${EDGE_DOMAIN}`

The certificate is shared by all service vhosts on the host Nginx instance.

Because the host does not expose `80` or `443`, `HTTP-01` and `TLS-ALPN-01` are not part of this design.

## Reverse Proxy Design

The host Nginx instance:

- listens on a single configured external HTTPS port from `edge-routing.env`
- loads the wildcard certificate from ACME
- matches incoming requests by `server_name`
- proxies to fixed internal VM backends

Backend mapping remains public and declarative because it is structural, not secret.

Example backend mapping:

- `RSSHUB_HOST.${EDGE_DOMAIN}` -> `app-vm` `192.168.31.213:1200`
- `JELLYFIN_HOST.${EDGE_DOMAIN}` -> `media-vm` `192.168.31.212:8096`
- `SONARR_HOST.${EDGE_DOMAIN}` -> `media-vm` `192.168.31.212:8989`
- `RADARR_HOST.${EDGE_DOMAIN}` -> `media-vm` `192.168.31.212:7878`
- `PROWLARR_HOST.${EDGE_DOMAIN}` -> `media-vm` `192.168.31.212:9696`
- `QBITTORRENT_HOST.${EDGE_DOMAIN}` -> `media-vm` `192.168.31.212:8080`
- `ROUTER_HOST.${EDGE_DOMAIN}` -> `router-vm` `192.168.31.214:9090`

Nginx is the only TLS termination point in the system.

## Bootstrap and Failure Behavior

The edge layer must be bootstrap-safe.

### No edge secrets present

- host boots normally
- all VMs boot normally
- DDNS service is skipped
- ACME issuance is skipped
- Nginx edge vhosts are skipped

### Routing secret present, credential secret missing

- host boots normally
- Nginx may still be skipped if certificate prerequisites are missing
- DDNS and ACME are skipped because Alibaba Cloud credentials are unavailable

### Credentials present, DNS or API error occurs

- host remains healthy
- DDNS logs a failure
- ACME may fail renewal or issuance
- existing Nginx configuration should continue serving the last valid certificate if already issued

### Wildcard DNS not yet propagated

- ACME issuance may temporarily fail
- Nginx should not be considered ready until certificates exist

The edge layer must not be allowed to block host or VM boot.

## Module Boundaries

Add a dedicated host edge module tree:

- `modules/host/edge/default.nix`
- `modules/host/edge/secrets.nix`
- `modules/host/edge/ddns.nix`
- `modules/host/edge/acme.nix`
- `modules/host/edge/nginx.nix`

### `modules/host/edge/secrets.nix`

Responsibilities:

- declare `agenix` secrets for edge credentials and edge routing
- export runtime file paths
- enable services only when required files exist

### `modules/host/edge/ddns.nix`

Responsibilities:

- determine the current public IPv6
- update wildcard and optional apex `AAAA` records through Alibaba Cloud DNS
- run on a timer
- log clearly on failure

### `modules/host/edge/acme.nix`

Responsibilities:

- configure `security.acme`
- load Alibaba Cloud credentials from runtime secret files
- request wildcard and optional apex certificates

### `modules/host/edge/nginx.nix`

Responsibilities:

- load runtime routing data
- generate `server_name` values from secret hostname prefixes and secret domain
- proxy to public, fixed backend targets
- bind only the configured external HTTPS port

## Data Flow

1. Host boots.
2. If present, `agenix` decrypts edge secrets on the host.
3. DDNS timer updates wildcard and optional apex `AAAA` records to the current public IPv6.
4. ACME uses Alibaba Cloud DNS `DNS-01` to issue or renew the wildcard certificate.
5. Nginx loads the certificate and hostname routing config.
6. External client accesses `https://service.${EDGE_DOMAIN}:${EDGE_HTTPS_PORT}` over IPv6.
7. Host Nginx terminates TLS and proxies to the correct VM backend.

## Security Notes

This design improves confidentiality of ingress details by keeping them out of Git, but it is not a primary security boundary.

Real security still depends on:

- limiting exposed services
- correct TLS configuration
- keeping services patched
- authentication and authorization on proxied services
- host firewall policy

The value of secretizing domain and port data is mainly reducing passive exposure and casual discovery.

## Operations

Initial operator flow:

1. deploy the host without edge secrets
2. obtain the host recipient and add it to `agenix`
3. create `edge-aliyun.env.age`
4. create `edge-routing.env.age`
5. rebuild the host
6. verify DDNS updates
7. verify ACME issuance
8. verify Nginx vhosts and proxy reachability

Operational checks should include:

- edge secret files exist under `/run/agenix/`
- DDNS timer and service status
- ACME certificate presence and renewal status
- Nginx listening on the configured HTTPS port
- hostname-based routing to each backend

## Non-Goals

This design does not include:

- public exposure of raw VM service ports
- per-VM certificate management
- OpenResty or Caddy migration
- hiding services behind a private mesh VPN only
- WAF or bot-management features
- IPv4 ingress

## Implementation Notes

The implementation should prefer:

- bootstrap-safe conditional module wiring using `builtins.pathExists`
- systemd services and timers for DDNS
- NixOS native `security.acme` and `services.nginx`
- public backend target definitions in `lib/homelab-config.nix`
- secret runtime parsing for domain, host prefixes, and HTTPS port

The resulting implementation should preserve the current VM boundaries and avoid moving service logic into the host.
