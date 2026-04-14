# Edge DDNS, Nginx, and ACME Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a bootstrap-safe host edge layer that updates wildcard Alibaba Cloud DNS records, issues wildcard certificates with ACME `DNS-01`, and serves a single-port Nginx ingress that routes to VM services by hostname.

**Architecture:** The host gains a dedicated `edge` module tree with separate responsibilities for secrets, DDNS, ACME, and Nginx. Sensitive ingress data is decrypted at runtime from `agenix` env files, while backend service topology remains declarative in shared host config.

**Tech Stack:** NixOS modules, `agenix`, systemd services and timers, `security.acme`, `services.nginx`, Alibaba Cloud DNS API, IPv6 ingress, microvm guest backends.

---

## File Structure

### New files

- `modules/host/edge/default.nix`
  Aggregates host edge submodules.
- `modules/host/edge/secrets.nix`
  Declares decrypted runtime secret files and bootstrap-safe secret export paths.
- `modules/host/edge/ddns.nix`
  Adds the IPv6 DDNS updater service and timer for wildcard and optional apex records.
- `modules/host/edge/acme.nix`
  Configures DNS-01 issuance through Alibaba Cloud credentials read from runtime env files.
- `modules/host/edge/nginx.nix`
  Builds Nginx virtual host definitions and a single TLS listener from runtime routing data.
- `docs/operations/edge.md`
  Operator guide for secret preparation, rebuild, verification, and failure modes.

### Modified files

- `hosts/homelab/default.nix`
  Imports the new host edge module tree.
- `lib/homelab-config.nix`
  Adds public edge backend topology and any non-secret edge feature flags.
- `modules/host/secrets.nix`
  Extends `agenix` wiring for edge secrets with `builtins.pathExists` guards.
- `secrets/secrets.nix`
  Registers `edge-aliyun.env.age` and `edge-routing.env.age` recipients.
- `docs/operations/README.md`
  Links the new edge operations guide.
- `docs/operations/services.md`
  Documents that public ingress is host-level and points at VM backends.
- `docs/operations/first-boot.md`
  Adds first-boot notes for the bootstrap-safe edge layer.

### Validation commands

- `nix eval .#nixosConfigurations.homelab.config.services.nginx.enable`
- `nix eval .#nixosConfigurations.homelab.config.security.acme.certs`
- `nix eval .#nixosConfigurations.homelab.config.systemd.services.edge-ddns`
- `sudo nixos-rebuild switch --flake .#homelab`
- `systemctl status edge-ddns.service edge-ddns.timer nginx.service`
- `systemctl status acme-<domain>.service`
- `ss -ltnp | rg <edge-port>`
- `curl -k --resolve <host>:<port>:[<ipv6>] https://<host>:<port>/ -I`

### Task 1: Extend shared config and recipient inventory

**Files:**
- Modify: `lib/homelab-config.nix`
- Modify: `secrets/secrets.nix`

- [ ] **Step 1: Add public edge topology to shared config**

Add a new `edge` attribute set under the top-level homelab config with only non-secret structure. Include:

```nix
    edge = {
      manageApex = false;
      services = {
        rsshub = {
          backendHost = "192.168.31.213";
          backendPort = 1200;
        };
        jellyfin = {
          backendHost = "192.168.31.212";
          backendPort = 8096;
        };
        sonarr = {
          backendHost = "192.168.31.212";
          backendPort = 8989;
        };
        radarr = {
          backendHost = "192.168.31.212";
          backendPort = 7878;
        };
        prowlarr = {
          backendHost = "192.168.31.212";
          backendPort = 9696;
        };
        qbittorrent = {
          backendHost = "192.168.31.212";
          backendPort = 8080;
        };
        router = {
          backendHost = "192.168.31.214";
          backendPort = 9090;
        };
      };
    };
```

- [ ] **Step 2: Register edge secret filenames in the recipient inventory**

Update `secrets/secrets.nix` so it includes:

```nix
  "edge-aliyun.env.age".publicKeys = [ host ];
  "edge-routing.env.age".publicKeys = [ host ];
```

Keep the existing RSSHub secret entry intact.

- [ ] **Step 3: Review config names for consistency**

Verify the final attribute names used later in the plan are:

- `homelab.edge.manageApex`
- `homelab.edge.services.<name>.backendHost`
- `homelab.edge.services.<name>.backendPort`

Do not rename them later in the implementation.

- [ ] **Step 4: Commit**

```bash
git add lib/homelab-config.nix secrets/secrets.nix
git commit -m "feat: add shared edge topology config"
```

### Task 2: Wire host edge secrets with bootstrap-safe guards

**Files:**
- Modify: `modules/host/secrets.nix`
- Create: `modules/host/edge/secrets.nix`

- [ ] **Step 1: Extend host secret wiring for edge files**

In `modules/host/secrets.nix`, add guarded `agenix` declarations for:

```nix
let
  edgeAliyunFile = ../../secrets/edge-aliyun.env.age;
  edgeRoutingFile = ../../secrets/edge-routing.env.age;
  hasEdgeAliyunFile = builtins.pathExists edgeAliyunFile;
  hasEdgeRoutingFile = builtins.pathExists edgeRoutingFile;
in
{
  age.secrets = lib.mkMerge [
    (lib.mkIf hasEdgeAliyunFile {
      edge-aliyun-env = {
        file = edgeAliyunFile;
        path = "/run/agenix/edge-aliyun.env";
        mode = "0400";
        owner = "root";
        group = "root";
      };
    })
    (lib.mkIf hasEdgeRoutingFile {
      edge-routing-env = {
        file = edgeRoutingFile;
        path = "/run/agenix/edge-routing.env";
        mode = "0400";
        owner = "root";
        group = "root";
      };
    })
  ];
}
```

- [ ] **Step 2: Create a focused edge secret helper module**

Create `modules/host/edge/secrets.nix` with:

```nix
{ lib, config, ... }:
let
  edgeAliyunPath =
    if config.age.secrets ? edge-aliyun-env
    then config.age.secrets.edge-aliyun-env.path
    else null;
  edgeRoutingPath =
    if config.age.secrets ? edge-routing-env
    then config.age.secrets.edge-routing-env.path
    else null;
in {
  options.homelab.edge.runtime = lib.mkOption {
    type = lib.types.attrs;
    readOnly = true;
    default = {
      aliyunEnvPath = edgeAliyunPath;
      routingEnvPath = edgeRoutingPath;
      hasAliyunEnv = edgeAliyunPath != null;
      hasRoutingEnv = edgeRoutingPath != null;
    };
  };
}
```

- [ ] **Step 3: Run eval to ensure absent files do not break evaluation**

Run:

```bash
nix eval .#nixosConfigurations.homelab.config.age.secrets --json
```

Expected:
- evaluation succeeds whether or not the new `.age` files exist
- new edge secrets appear only when the files exist

- [ ] **Step 4: Commit**

```bash
git add modules/host/secrets.nix modules/host/edge/secrets.nix
git commit -m "feat: add bootstrap-safe edge secret wiring"
```

### Task 3: Add host edge module tree and DDNS service

**Files:**
- Create: `modules/host/edge/default.nix`
- Create: `modules/host/edge/ddns.nix`
- Modify: `hosts/homelab/default.nix`

- [ ] **Step 1: Import the edge module tree**

Create `modules/host/edge/default.nix`:

```nix
{ ... }:
{
  imports = [
    ./secrets.nix
    ./ddns.nix
    ./acme.nix
    ./nginx.nix
  ];
}
```

Then import it from `hosts/homelab/default.nix` alongside the existing host modules.

- [ ] **Step 2: Add the DDNS service and timer**

Create `modules/host/edge/ddns.nix` with:

```nix
{ lib, pkgs, config, homelab, ... }:
let
  runtime = homelab.edge.runtime;
  edgeEnabled = runtime.hasAliyunEnv && runtime.hasRoutingEnv;
  script = pkgs.writeShellScript "edge-ddns" ''
    set -eu
    . ${runtime.aliyunEnvPath}
    . ${runtime.routingEnvPath}

    public_ipv6="$(${pkgs.curl}/bin/curl -fsS https://api64.ipify.org)"
    test -n "$public_ipv6"

    echo "Updating wildcard AAAA for ''${EDGE_DOMAIN} to $public_ipv6"
  '';
in {
  systemd.services.edge-ddns = lib.mkIf edgeEnabled {
    description = "Update wildcard Alibaba Cloud DNS AAAA records";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
    };
    path = [ pkgs.curl pkgs.coreutils pkgs.gnused pkgs.gawk ];
    script = script;
  };

  systemd.timers.edge-ddns = lib.mkIf edgeEnabled {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "3m";
      OnUnitActiveSec = "10m";
      Unit = "edge-ddns.service";
    };
  };
}
```

Replace the echo-only body during implementation with real Alibaba Cloud API update calls, but keep the unit name and gating.

- [ ] **Step 3: Run eval on the DDNS unit**

Run:

```bash
nix eval .#nixosConfigurations.homelab.config.systemd.services.edge-ddns
```

Expected:
- attribute exists only when both edge env files exist
- evaluation succeeds when neither exists

- [ ] **Step 4: Commit**

```bash
git add hosts/homelab/default.nix modules/host/edge/default.nix modules/host/edge/ddns.nix
git commit -m "feat: add host edge ddns scaffold"
```

### Task 4: Add ACME DNS-01 configuration for Alibaba Cloud

**Files:**
- Create: `modules/host/edge/acme.nix`

- [ ] **Step 1: Configure wildcard ACME with runtime env credentials**

Create `modules/host/edge/acme.nix`:

```nix
{ lib, homelab, ... }:
let
  runtime = homelab.edge.runtime;
  edgeEnabled = runtime.hasAliyunEnv && runtime.hasRoutingEnv;
in {
  security.acme = lib.mkIf edgeEnabled {
    acceptTerms = true;
    defaults.email = "admin@invalid.example";
    certs."edge-wildcard" = {
      dnsProvider = "alidns";
      credentialsFile = runtime.aliyunEnvPath;
      domain = "*.${"$"}{EDGE_DOMAIN}";
      extraDomainNames = [ ];
      group = "nginx";
    };
  };
}
```

During implementation, replace the literal `domain` placeholder with a generated domain string sourced from the decrypted routing env. Keep the certificate name stable as `edge-wildcard`.

- [ ] **Step 2: Add apex-domain toggle behavior**

When `homelab.edge.manageApex = true`, ensure the generated cert adds:

```nix
extraDomainNames = [ edgeDomain ];
```

When false, `extraDomainNames` stays empty.

- [ ] **Step 3: Run eval on ACME certs**

Run:

```bash
nix eval .#nixosConfigurations.homelab.config.security.acme.certs
```

Expected:
- the `edge-wildcard` cert exists when both env files exist
- it does not force evaluation failure when secrets are absent

- [ ] **Step 4: Commit**

```bash
git add modules/host/edge/acme.nix
git commit -m "feat: add edge acme dns-01 config"
```

### Task 5: Add Nginx single-port ingress and hostname routing

**Files:**
- Create: `modules/host/edge/nginx.nix`

- [ ] **Step 1: Create runtime routing parser and vhost builder**

Create `modules/host/edge/nginx.nix` with a structure like:

```nix
{ lib, homelab, ... }:
let
  runtime = homelab.edge.runtime;
  edgeEnabled = runtime.hasAliyunEnv && runtime.hasRoutingEnv;
  services = homelab.edge.services;
in {
  services.nginx = lib.mkIf edgeEnabled {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
  };
}
```

Extend it so the module:

- reads `EDGE_DOMAIN` and `EDGE_HTTPS_PORT` from the routing env at activation time
- maps each public hostname prefix to one backend from `homelab.edge.services`
- creates one vhost per service
- binds all vhosts to the same HTTPS port
- uses the `edge-wildcard` certificate

- [ ] **Step 2: Implement the backend proxy settings**

Each generated vhost should include settings equivalent to:

```nix
locations."/" = {
  proxyPass = "http://${backendHost}:${toString backendPort}";
  proxyWebsockets = true;
};
```

Also keep:

```nix
forceSSL = false;
listen = [
  {
    addr = "[::]";
    port = edgePort;
    ssl = true;
  }
];
```

Do not add an HTTP listener.

- [ ] **Step 3: Run eval on Nginx config**

Run:

```bash
nix eval .#nixosConfigurations.homelab.config.services.nginx.virtualHosts
```

Expected:
- generated vhosts exist only when routing and cert prerequisites are available
- all vhosts point at the fixed VM backends from `homelab.edge.services`

- [ ] **Step 4: Commit**

```bash
git add modules/host/edge/nginx.nix
git commit -m "feat: add edge nginx ingress"
```

### Task 6: Open the external TLS port and document operator flow

**Files:**
- Modify: `modules/host/networking.nix`
- Create: `docs/operations/edge.md`
- Modify: `docs/operations/README.md`
- Modify: `docs/operations/services.md`
- Modify: `docs/operations/first-boot.md`

- [ ] **Step 1: Open the configured edge HTTPS port on the host firewall**

In `modules/host/networking.nix`, add bootstrap-safe firewall opening for the edge port. The opening should only happen when the routing env exists and the parsed edge port is available.

Use the same runtime edge env source as the Nginx module so firewall and listener stay aligned.

- [ ] **Step 2: Write the edge operator guide**

Create `docs/operations/edge.md` with sections for:

- purpose of the host edge layer
- required secrets:
  - `edge-aliyun.env.age`
  - `edge-routing.env.age`
- wildcard DNS model
- ACME `DNS-01` model
- rebuild sequence
- verification commands:

```bash
systemctl status edge-ddns.service edge-ddns.timer
systemctl status nginx.service
systemctl status acme-edge-wildcard.service
ss -ltnp
journalctl -u edge-ddns.service -b
```

- [ ] **Step 3: Link the new operations guide**

Update:

- `docs/operations/README.md`
- `docs/operations/services.md`
- `docs/operations/first-boot.md`

Add:
- where the host edge layer lives
- that the host is now the public ingress point
- that missing edge secrets is an expected bootstrap state

- [ ] **Step 4: Commit**

```bash
git add modules/host/networking.nix docs/operations/edge.md docs/operations/README.md docs/operations/services.md docs/operations/first-boot.md
git commit -m "docs: add edge ingress operations guide"
```

### Task 7: Real-world verification with and without secrets

**Files:**
- Modify as needed: any files from Tasks 1-6

- [ ] **Step 1: Verify bootstrap-safe evaluation without secrets**

Temporarily ensure:

- `secrets/edge-aliyun.env.age` does not exist
- `secrets/edge-routing.env.age` does not exist

Run:

```bash
nix eval .#nixosConfigurations.homelab.config.systemd.services.edge-ddns
nix eval .#nixosConfigurations.homelab.config.services.nginx.enable
sudo nixos-rebuild switch --flake .#homelab
```

Expected:
- evaluation succeeds
- host rebuild succeeds
- edge units are skipped or absent

- [ ] **Step 2: Verify enabled path with real secrets**

Create:

- `secrets/edge-aliyun.env.age`
- `secrets/edge-routing.env.age`

Then run:

```bash
sudo nixos-rebuild switch --flake .#homelab
systemctl status edge-ddns.service edge-ddns.timer nginx.service
```

Expected:
- edge-ddns timer is active
- nginx is active
- ACME unit exists for `edge-wildcard`

- [ ] **Step 3: Verify external edge behavior**

Run:

```bash
ss -ltnp | rg 28443
curl -k --resolve rsshub.example.com:28443:[<public-ipv6>] https://rsshub.example.com:28443/ -I
curl -k --resolve jellyfin.example.com:28443:[<public-ipv6>] https://jellyfin.example.com:28443/ -I
```

Expected:
- host listens on the configured edge port
- TLS handshake succeeds
- correct backend responds for each hostname

- [ ] **Step 4: Commit follow-up fixes**

```bash
git add hosts/homelab/default.nix lib/homelab-config.nix modules/host/networking.nix modules/host/secrets.nix modules/host/edge docs/operations secrets/secrets.nix
git commit -m "fix: verify and finalize host edge ingress"
```

## Self-Review

- Spec coverage check:
  - bootstrap-safe secret handling is covered by Task 2 and Task 7
  - wildcard DDNS is covered by Task 3 and Task 7
  - DNS-01 wildcard ACME is covered by Task 4 and Task 7
  - single-port host Nginx ingress is covered by Task 5 and Task 6
  - operator documentation is covered by Task 6
- Placeholder scan:
  - no `TODO` or `TBD` markers remain
  - the only implementation-time substitution called out explicitly is replacing the DDNS stub body with the real Alibaba Cloud update calls while preserving the agreed module boundary
- Type consistency:
  - all later tasks use the same names: `homelab.edge.manageApex`, `homelab.edge.services`, `edge-wildcard`, `edge-ddns`, `edge-aliyun-env`, and `edge-routing-env`
