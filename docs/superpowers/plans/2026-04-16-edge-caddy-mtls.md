# Edge Caddy and mTLS Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the host public ingress direction with a Caddy-based edge layer that reverse proxies to VM services and enforces `mTLS` for all currently public sites.

**Architecture:** The host gets a dedicated Caddy edge module tree that reads shared service topology from `lib/homelab-config.nix` and references host-local PKI files under `/srv/data/edge/`. DDNS remains host-side, while Caddy becomes the only public TLS and client-authentication boundary, with per-service `requireMtls` switches for future exceptions.

**Tech Stack:** NixOS modules, `services.caddy`, systemd, host-local PKI files, Alibaba Cloud DNS DDNS, IPv6 ingress, microvm guest backends, mutual TLS.

---

## File Structure

### New files

- `modules/host/edge/caddy.nix`
  Configures the host Caddy service, Caddyfile generation, host-local PKI paths, and per-service `mTLS` policy.
- `modules/host/edge/pki.nix`
  Declares host-local edge PKI paths, bootstrap-safe directory creation, and Caddy prerequisites.
- `docs/operations/edge-caddy.md`
  Operator guide for the Caddy ingress, device certificates, PKI layout, and verification steps.

### Modified files

- `lib/homelab-config.nix`
  Replaces the old edge topology shape with Caddy-oriented service metadata: edge port, hostname prefixes, backend targets, and `requireMtls`.
- `modules/host/edge/default.nix`
  Imports the new Caddy and PKI modules and drops the now-superseded Nginx ingress direction.
- `modules/host/edge/ddns.nix`
  Keeps DDNS focused on wildcard and optional apex records, aligned with the Caddy ingress design.
- `modules/host/networking.nix`
  Opens the public edge HTTPS port on the host firewall.
- `modules/host/storage.nix`
  Ensures `/srv/data/edge/` directory structure exists on the host.
- `docs/operations/README.md`
  Links the new edge Caddy operator guide.
- `docs/operations/services.md`
  Documents that the host public ingress is now Caddy-based.
- `docs/operations/first-boot.md`
  Adds bootstrap notes and checks for the Caddy edge layer.

### Existing files intentionally left in place for now

- `modules/host/edge/acme.nix`
  May remain as a no-op stub unless and until server-certificate automation is wired back in.
- `modules/host/edge/nginx.nix`
  Should be removed or turned into an inert compatibility stub once Caddy becomes the only supported ingress path.

### Validation commands

- `nix eval .#nixosConfigurations.homelab.config.services.caddy.enable`
- `nix eval .#nixosConfigurations.homelab.config.systemd.services.edge-ddns`
- `sudo nixos-rebuild switch --flake .#homelab`
- `systemctl status caddy.service edge-ddns.service edge-ddns.timer`
- `ss -ltnp | rg <edge-port>`
- `curl -vk --resolve <host>:<port>:[<public-ipv6>] https://<host>:<port>/`
- `openssl s_client -connect [<public-ipv6>]:<port> -servername <host> -cert <client.pem> -key <client.key>`

## Task 1: Reshape shared edge topology for Caddy

**Files:**
- Modify: `lib/homelab-config.nix`

- [ ] **Step 1: Replace the old edge topology shape**

Update `lib/homelab-config.nix` so the `edge` block describes Caddy ingress policy directly. Replace the current service map with:

```nix
  edge = {
    port = 28443;
    manageApex = false;
    domain = "example.com";
    services = {
      rsshub = {
        host = "rsshub";
        backendHost = "192.168.31.213";
        backendPort = 1200;
        requireMtls = true;
      };
      jellyfin = {
        host = "jellyfin";
        backendHost = "192.168.31.212";
        backendPort = 8096;
        requireMtls = true;
      };
      sonarr = {
        host = "sonarr";
        backendHost = "192.168.31.212";
        backendPort = 8989;
        requireMtls = true;
      };
      radarr = {
        host = "radarr";
        backendHost = "192.168.31.212";
        backendPort = 7878;
        requireMtls = true;
      };
      prowlarr = {
        host = "prowlarr";
        backendHost = "192.168.31.212";
        backendPort = 9696;
        requireMtls = true;
      };
      qbittorrent = {
        host = "qb";
        backendHost = "192.168.31.212";
        backendPort = 8080;
        requireMtls = true;
      };
      router = {
        host = "router";
        backendHost = "192.168.31.214";
        backendPort = 9090;
        requireMtls = true;
      };
    };
  };
```

- [ ] **Step 2: Keep names stable for later tasks**

Verify the final public API names are:

- `homelab.edge.port`
- `homelab.edge.domain`
- `homelab.edge.manageApex`
- `homelab.edge.services.<name>.host`
- `homelab.edge.services.<name>.backendHost`
- `homelab.edge.services.<name>.backendPort`
- `homelab.edge.services.<name>.requireMtls`

- [ ] **Step 3: Commit**

```bash
git add lib/homelab-config.nix
git commit -m "feat: reshape edge topology for caddy"
```

## Task 2: Add host-local PKI and edge directory model

**Files:**
- Create: `modules/host/edge/pki.nix`
- Modify: `modules/host/storage.nix`
- Modify: `modules/host/edge/default.nix`

- [ ] **Step 1: Extend host storage directories**

Update `modules/host/storage.nix` so the host creates:

```nix
      "/srv/data/edge"
      "/srv/data/edge/caddy"
      "/srv/data/edge/pki"
      "/srv/data/edge/pki/server"
      "/srv/data/edge/pki/client-ca"
      "/srv/data/edge/pki/clients"
```

alongside the existing storage directories.

- [ ] **Step 2: Add a dedicated PKI module**

Create `modules/host/edge/pki.nix`:

```nix
{ homelab, ... }:
let
  edgeRoot = "/srv/data/edge";
in {
  options.homelab.edge.paths = {
    root = {
      readOnly = true;
      default = edgeRoot;
    };
    caddyConfigDir = {
      readOnly = true;
      default = "${edgeRoot}/caddy";
    };
    caddyfile = {
      readOnly = true;
      default = "${edgeRoot}/caddy/Caddyfile";
    };
    serverPkiDir = {
      readOnly = true;
      default = "${edgeRoot}/pki/server";
    };
    clientCaDir = {
      readOnly = true;
      default = "${edgeRoot}/pki/client-ca";
    };
    clientBundlesDir = {
      readOnly = true;
      default = "${edgeRoot}/pki/clients";
    };
  };
}
```

If needed, add explicit option types while keeping these names unchanged.

- [ ] **Step 3: Import the PKI module from the edge root**

Update `modules/host/edge/default.nix` to import `./pki.nix` before `./caddy.nix`.

- [ ] **Step 4: Commit**

```bash
git add modules/host/storage.nix modules/host/edge/pki.nix modules/host/edge/default.nix
git commit -m "feat: add edge host-local pki paths"
```

## Task 3: Add host Caddy service scaffold

**Files:**
- Create: `modules/host/edge/caddy.nix`
- Modify: `modules/host/edge/default.nix`

- [ ] **Step 1: Add the Caddy module import**

Update `modules/host/edge/default.nix` so the imports list includes:

```nix
    ./pki.nix
    ./caddy.nix
```

Keep existing imports intact until later cleanup.

- [ ] **Step 2: Add a bootstrap-safe Caddy service scaffold**

Create `modules/host/edge/caddy.nix` with a minimal host service shape:

```nix
{ lib, config, pkgs, ... }:
let
  edge = config.homelab.edge;
  paths = edge.paths;
  edgeEnabled = builtins.pathExists paths.caddyfile;
in {
  services.caddy = lib.mkIf edgeEnabled {
    enable = true;
    configFile = paths.caddyfile;
  };

  systemd.services.caddy = lib.mkIf edgeEnabled {
    serviceConfig = {
      SupplementaryGroups = [ "caddy" ];
    };
  };
}
```

The first version should be deliberately bootstrap-safe:

- no `Caddyfile` -> no public ingress
- host boot still succeeds

- [ ] **Step 3: Add a runtime-generated placeholder Caddyfile path only if needed**

If Caddy on this repo’s NixOS version requires a file to exist at eval time, generate a minimal placeholder via Nix:

```nix
environment.etc."caddy/Caddyfile".text = ''
  {
  }
'';
```

Only do this if the service cannot stay bootstrap-safe otherwise.

- [ ] **Step 4: Commit**

```bash
git add modules/host/edge/default.nix modules/host/edge/caddy.nix
git commit -m "feat: add host caddy ingress scaffold"
```

## Task 4: Generate hostname-based Caddy routing with per-service mTLS policy

**Files:**
- Modify: `modules/host/edge/caddy.nix`

- [ ] **Step 1: Add Caddyfile generation from shared topology**

Update `modules/host/edge/caddy.nix` so it renders a Caddyfile from `homelab.edge.services`.

For each service, generate a site block like:

```caddy
rsshub.example.com:28443 {
	reverse_proxy 192.168.31.213:1200
}
```

Build these blocks from:

- `edge.domain`
- `edge.port`
- `edge.services.<name>.host`
- `edge.services.<name>.backendHost`
- `edge.services.<name>.backendPort`

- [ ] **Step 2: Add mTLS enforcement for `requireMtls = true` sites**

For services marked `requireMtls = true`, render:

```caddy
	tls /srv/data/edge/pki/server/fullchain.pem /srv/data/edge/pki/server/privkey.pem {
		client_auth {
			mode require_and_verify
			trust_pool file /srv/data/edge/pki/client-ca/ca.pem
		}
	}
```

For services marked `requireMtls = false`, keep normal TLS without `client_auth`.

- [ ] **Step 3: Write the generated Caddyfile to the host-local edge path**

Use a generated file source that Caddy can consume, but preserve the host-local path contract:

- Nix may generate the content
- the configured path exposed to operators remains `/srv/data/edge/caddy/Caddyfile`

If exact path generation cannot remain purely declarative, document and use a small systemd oneshot to install the file there.

- [ ] **Step 4: Commit**

```bash
git add modules/host/edge/caddy.nix
git commit -m "feat: add caddy hostname routing with mtls"
```

## Task 5: Align DDNS and firewall with Caddy ingress

**Files:**
- Modify: `modules/host/edge/ddns.nix`
- Modify: `modules/host/networking.nix`

- [ ] **Step 1: Align DDNS logging and intended behavior with wildcard ingress**

Update `modules/host/edge/ddns.nix` comments and log messages so they clearly reflect:

- wildcard `AAAA` record management
- optional apex record management through `edge.manageApex`
- independence from Caddy `mTLS`

Do not implement Alibaba Cloud API calls yet unless the task naturally requires it.

- [ ] **Step 2: Open the public edge port on the host firewall**

Update `modules/host/networking.nix` so the firewall opens:

```nix
allowedTCPPorts = [ 22 homelab.edge.port ];
```

If `allowedTCPPorts` is already a list literal, switch it to a concatenated form that preserves SSH and adds the edge port.

- [ ] **Step 3: Commit**

```bash
git add modules/host/edge/ddns.nix modules/host/networking.nix
git commit -m "feat: open caddy edge ingress port"
```

## Task 6: Document operator flow for Caddy and device certificates

**Files:**
- Create: `docs/operations/edge-caddy.md`
- Modify: `docs/operations/README.md`
- Modify: `docs/operations/services.md`
- Modify: `docs/operations/first-boot.md`

- [ ] **Step 1: Write the new operator guide**

Create `docs/operations/edge-caddy.md` with sections for:

- host public ingress responsibilities
- host-local PKI layout under `/srv/data/edge/`
- server certificate files used by Caddy
- client CA and per-device certificate flow
- how to export `.p12` bundles
- how to reload Caddy
- how to verify `mTLS`

Include verification commands:

```bash
systemctl status caddy.service
ss -ltnp
journalctl -u caddy.service -b
curl -vk https://rsshub.example.com:28443/
openssl s_client -connect [<public-ipv6>]:28443 -servername rsshub.example.com -cert client.pem -key client.key
```

- [ ] **Step 2: Link the guide from the operations index**

Update `docs/operations/README.md` with an entry for the host Caddy ingress guide.

- [ ] **Step 3: Update service and first-boot docs**

Update:

- `docs/operations/services.md`
- `docs/operations/first-boot.md`

to reflect:

- host public ingress is Caddy-based
- all current public sites require `mTLS`
- lack of PKI files means public ingress is unavailable by design

- [ ] **Step 4: Commit**

```bash
git add docs/operations/edge-caddy.md docs/operations/README.md docs/operations/services.md docs/operations/first-boot.md
git commit -m "docs: add caddy mtls edge operations guide"
```

## Task 7: Verify fail-closed behavior and public access control

**Files:**
- Modify as needed: any files from Tasks 1-6

- [ ] **Step 1: Verify bootstrap-safe rebuild without PKI material**

Ensure the host-local PKI files do not exist yet, then run:

```bash
sudo nixos-rebuild switch --flake .#homelab
systemctl status caddy.service
```

Expected:

- rebuild succeeds
- host and VMs still boot
- Caddy is disabled, inactive, or otherwise fail-closed

- [ ] **Step 2: Verify enabled path with server cert and client CA in place**

Create or place:

- `/srv/data/edge/pki/server/fullchain.pem`
- `/srv/data/edge/pki/server/privkey.pem`
- `/srv/data/edge/pki/client-ca/ca.pem`

Then run:

```bash
sudo nixos-rebuild switch --flake .#homelab
systemctl status caddy.service
ss -ltnp | rg 28443
```

Expected:

- Caddy is active
- host listens on the configured edge port

- [ ] **Step 3: Verify mTLS enforcement**

Run without a client cert:

```bash
curl -vk --resolve rsshub.example.com:28443:[<public-ipv6>] https://rsshub.example.com:28443/
```

Expected:

- handshake or authorization fails
- request does not reach backend

Run with a valid client cert:

```bash
openssl s_client \
  -connect [<public-ipv6>]:28443 \
  -servername rsshub.example.com \
  -cert /path/to/client.pem \
  -key /path/to/client.key
```

Expected:

- handshake succeeds
- backend becomes reachable with a properly configured client

- [ ] **Step 4: Commit final integration fixes**

```bash
git add lib/homelab-config.nix modules/host/edge modules/host/networking.nix modules/host/storage.nix docs/operations
git commit -m "fix: finalize caddy mtls edge integration"
```

## Self-Review

- Spec coverage check:
  - Caddy replaces Nginx as public ingress in Tasks 1, 3, and 4
  - all current public services requiring `mTLS` is covered in Tasks 1 and 4
  - future per-service opt-out is preserved by `requireMtls` in Tasks 1 and 4
  - host-local PKI storage is covered in Task 2 and Task 6
  - DDNS continuity is covered in Task 5
  - first deployment and fail-closed behavior are covered in Task 6 and Task 7
- Placeholder scan:
  - no `TODO`/`TBD` markers remain
  - each task names exact files and commands
- Type consistency:
  - the plan consistently uses `homelab.edge.port`, `homelab.edge.domain`, `homelab.edge.services.<name>.host`, `backendHost`, `backendPort`, and `requireMtls`
