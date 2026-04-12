# Operations Documentation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a dedicated operator-facing `docs/operations/` documentation area that explains system structure, service configuration locations, secrets, and first-boot behavior while keeping `INSTALL.md` focused on installation.

**Architecture:** Add a small set of focused operations documents with one clear responsibility each, then tighten `INSTALL.md` so it links outward instead of carrying mixed operational detail. Reuse the existing repository structure and recent RSSHub secret-management work as the factual source for paths, boundaries, and bootstrap behavior.

**Tech Stack:** Markdown, existing repository docs, NixOS homelab module layout

---

## File Structure

Planned file changes and responsibilities:

- Create: `docs/operations/README.md`
  Navigation entry point for operators.
- Create: `docs/operations/architecture-map.md`
  Maps major system boundaries and their repository entry points.
- Create: `docs/operations/services.md`
  Shows where major services live and which files configure them.
- Create: `docs/operations/secrets.md`
  Explains the current secret-management model, bootstrap flow, and relevant files.
- Create: `docs/operations/first-boot.md`
  Explains first-boot validation and expected bootstrap-safe inactive states.
- Modify: `INSTALL.md`
  Keeps install steps intact while moving extended operations guidance behind links.

## Task 1: Create The Operations Docs Entry Point

**Files:**
- Create: `docs/operations/README.md`

- [ ] **Step 1: Write the failing existence check**

Run:

```bash
test -f docs/operations/README.md
```

Expected: FAIL because the file does not exist yet.

- [ ] **Step 2: Create the operations index**

Create `docs/operations/README.md` with this content:

```markdown
# Operations Guide

This directory is the operator-facing guide for the homelab after the base system has been installed.

Use these documents based on what you need to do:

- Understand the system layout: [`architecture-map.md`](./architecture-map.md)
- Find where a service is configured: [`services.md`](./services.md)
- Configure and rotate secrets: [`secrets.md`](./secrets.md)
- Validate the system after installation: [`first-boot.md`](./first-boot.md)

The installation flow itself remains in [`INSTALL.md`](../../INSTALL.md).
```

- [ ] **Step 3: Re-run the existence check**

Run:

```bash
test -f docs/operations/README.md
```

Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add docs/operations/README.md
git commit -m "docs: add operations guide index"
```

## Task 2: Document The System Architecture And Repository Entry Points

**Files:**
- Create: `docs/operations/architecture-map.md`

- [ ] **Step 1: Write the failing content check**

Run:

```bash
rg -n "app-vm|storage-vm|media-vm|hosts/homelab/default.nix|lib/homelab-config.nix" docs/operations/architecture-map.md
```

Expected: FAIL because the file does not exist yet.

- [ ] **Step 2: Create the architecture map**

Create `docs/operations/architecture-map.md` with this content:

```markdown
# Architecture Map

This document explains the major system boundaries in the homelab and where those boundaries are configured in the repository.

## Repository Roles

- `hosts/` defines top-level host composition.
- `modules/` contains implementation modules grouped by host or VM boundary.
- `vms/` defines the entrypoint for each service-group VM.
- `lib/homelab-config.nix` stores shared constants such as ports, image names, and VM settings.
- `secrets/` stores encrypted secret declarations and related secret material.

## Host

The host is assembled from [`hosts/homelab/default.nix`](../../hosts/homelab/default.nix).

Host-level behavior is implemented in:

- [`modules/host/boot.nix`](../../modules/host/boot.nix)
- [`modules/host/admin-user.nix`](../../modules/host/admin-user.nix)
- [`modules/host/ssh.nix`](../../modules/host/ssh.nix)
- [`modules/host/networking.nix`](../../modules/host/networking.nix)
- [`modules/host/storage.nix`](../../modules/host/storage.nix)
- [`modules/host/microvm-host.nix`](../../modules/host/microvm-host.nix)
- [`modules/host/secrets.nix`](../../modules/host/secrets.nix)

The host is responsible for:

- Booting the physical machine
- Mounting `/srv/data`
- Running the MicroVM host substrate
- Managing host networking and forwarded service ports
- Owning the decryption boundary for encrypted secrets

## Storage VM

The storage VM entrypoint is [`vms/storage-vm.nix`](../../vms/storage-vm.nix).

Its implementation modules live under [`modules/storage-vm/`](../../modules/storage-vm).

The storage VM is responsible for:

- Serving SMB and NFS
- Exposing shared storage data
- Mounting the host data root into the VM

## Media VM

The media VM entrypoint is [`vms/media-vm.nix`](../../vms/media-vm.nix).

Its implementation modules live under [`modules/media-vm/`](../../modules/media-vm).

The media VM is responsible for:

- Running the media application stack
- Keeping media-related runtime state private to the VM
- Using host-managed port forwarding for exposed media services

## App VM

The app VM entrypoint is [`vms/app-vm.nix`](../../vms/app-vm.nix).

Its implementation modules live under [`modules/app-vm/`](../../modules/app-vm).

The app VM is responsible for:

- Running lightweight application-tier services
- Hosting RSSHub as the first app-tier workload
- Keeping application runtime state private to the VM

## Shared Configuration

Shared constants are defined in [`lib/homelab-config.nix`](../../lib/homelab-config.nix).

This file is the first place to check for:

- Port numbers
- Image names
- VM memory and CPU settings
- Shared VM path conventions
```

- [ ] **Step 3: Re-run the content check**

Run:

```bash
rg -n "app-vm|storage-vm|media-vm|hosts/homelab/default.nix|lib/homelab-config.nix" docs/operations/architecture-map.md
```

Expected: PASS with matches for the VM boundaries and shared config file.

- [ ] **Step 4: Commit**

```bash
git add docs/operations/architecture-map.md
git commit -m "docs: add architecture map for operators"
```

## Task 3: Document Service Placement And Configuration Files

**Files:**
- Create: `docs/operations/services.md`

- [ ] **Step 1: Write the failing service lookup check**

Run:

```bash
rg -n "RSSHub|media-vm|storage-vm|modules/app-vm/containers.nix|modules/media-vm/containers.nix|modules/storage-vm" docs/operations/services.md
```

Expected: FAIL because the file does not exist yet.

- [ ] **Step 2: Create the services map**

Create `docs/operations/services.md` with this content:

```markdown
# Services

This document answers the question: where is this service configured?

## RSSHub

- Boundary: `app-vm`
- VM entrypoint: [`vms/app-vm.nix`](../../vms/app-vm.nix)
- Runtime module: [`modules/app-vm/containers.nix`](../../modules/app-vm/containers.nix)
- VM networking and port forwarding: [`modules/app-vm/microvm.nix`](../../modules/app-vm/microvm.nix)
- Shared ports and image values: [`lib/homelab-config.nix`](../../lib/homelab-config.nix)
- Secret handling: [`modules/host/secrets.nix`](../../modules/host/secrets.nix) and [`secrets/secrets.nix`](../../secrets/secrets.nix)

RSSHub is the first workload in the app-tier VM and should remain there unless the application boundary changes materially.

## Media Stack

- Boundary: `media-vm`
- VM entrypoint: [`vms/media-vm.nix`](../../vms/media-vm.nix)
- Runtime modules: [`modules/media-vm/containers.nix`](../../modules/media-vm/containers.nix), [`modules/media-vm/state.nix`](../../modules/media-vm/state.nix), and [`modules/media-vm/microvm.nix`](../../modules/media-vm/microvm.nix)
- Shared ports and image values: [`lib/homelab-config.nix`](../../lib/homelab-config.nix)

The media stack owns media-facing application services such as Jellyfin and the automation tools around it.

## Storage Protocols

- Boundary: `storage-vm`
- VM entrypoint: [`vms/storage-vm.nix`](../../vms/storage-vm.nix)
- SMB: [`modules/storage-vm/samba.nix`](../../modules/storage-vm/samba.nix)
- NFS: [`modules/storage-vm/nfs.nix`](../../modules/storage-vm/nfs.nix)
- Shared data exposure: [`modules/storage-vm/shares.nix`](../../modules/storage-vm/shares.nix) and [`modules/storage-vm/microvm.nix`](../../modules/storage-vm/microvm.nix)
- Shared ports and host storage values: [`lib/homelab-config.nix`](../../lib/homelab-config.nix)

The storage VM owns network file-sharing protocols and access to the shared data root.
```

- [ ] **Step 3: Re-run the service lookup check**

Run:

```bash
rg -n "RSSHub|media-vm|storage-vm|modules/app-vm/containers.nix|modules/media-vm/containers.nix|modules/storage-vm" docs/operations/services.md
```

Expected: PASS with matches for each service boundary and key config path.

- [ ] **Step 4: Commit**

```bash
git add docs/operations/services.md
git commit -m "docs: add service configuration map"
```

## Task 4: Document Secret Management And First-Boot Behavior

**Files:**
- Create: `docs/operations/secrets.md`
- Create: `docs/operations/first-boot.md`

- [ ] **Step 1: Write the failing docs grep**

Run:

```bash
rg -n "agenix|rsshub|ssh_host_ed25519_key|first boot|microvm@app-vm|inactive" docs/operations/secrets.md docs/operations/first-boot.md
```

Expected: FAIL because the files do not exist yet.

- [ ] **Step 2: Create the secret-management guide**

Create `docs/operations/secrets.md` with this content:

```markdown
# Secrets

This document explains how encrypted secrets are managed for the homelab.

## Current Model

The current design uses host-side decryption for application secrets.

- Encrypted secret declarations live in [`secrets/`](../../secrets)
- Host-side secret handling is implemented in [`modules/host/secrets.nix`](../../modules/host/secrets.nix)
- Shared secret metadata and shared VM path conventions live in [`lib/homelab-config.nix`](../../lib/homelab-config.nix)

## RSSHub Secret Flow

RSSHub secrets are intended to follow this model:

1. The host owns the decryption identity.
2. The repository stores encrypted secret artifacts.
3. The host decrypts the secret into a runtime path.
4. `app-vm` consumes the runtime secret file for RSSHub.

Relevant files:

- [`secrets/secrets.nix`](../../secrets/secrets.nix)
- [`modules/host/secrets.nix`](../../modules/host/secrets.nix)
- [`modules/app-vm/containers.nix`](../../modules/app-vm/containers.nix)
- [`modules/app-vm/microvm.nix`](../../modules/app-vm/microvm.nix)

## Bootstrap Expectations

After the first installation, the host SSH key is expected to act as the decryption identity.

The operator should expect a two-phase bootstrap:

1. Install the host and base VM layout.
2. Enroll the host recipient and add the encrypted RSSHub secret artifact.
3. Rebuild the host so the service can consume the secret.

Until the encrypted secret exists and can be decrypted, RSSHub may remain inactive. That is expected bootstrap behavior.

## Rotation And Updates

When a secret changes:

1. Update the encrypted secret artifact.
2. Rebuild the host.
3. Verify the host and `app-vm` consume the updated runtime file.

Plaintext secret staging files should not be committed.
```

- [ ] **Step 3: Create the first-boot guide**

Create `docs/operations/first-boot.md` with this content:

```markdown
# First Boot

This document explains what to validate after the initial installation and which bootstrap states are expected.

## Core Host Checks

Run:

```bash
hostnamectl
findmnt /
findmnt /boot
findmnt /srv/data
```

These checks confirm the host identity and expected filesystem layout.

## MicroVM Checks

Run:

```bash
systemctl status microvm@storage-vm
systemctl status microvm@media-vm
systemctl status microvm@app-vm
```

These checks confirm that the three service-group VMs started correctly.

## Service Reachability

Run:

```bash
curl -I http://127.0.0.1:1200
```

If RSSHub is fully configured, this should return an HTTP response.

## Expected Bootstrap-Safe States

During early bootstrap, some conditions are expected:

- `app-vm` may be running even if RSSHub is not yet usable
- RSSHub may remain inactive if its secret has not been enrolled yet
- Secret-gated service inactivity should be interpreted in the context of bootstrap state, not automatically as a host installation failure

## If A VM Fails To Start

Inspect:

```bash
journalctl -u microvm@storage-vm -b
journalctl -u microvm@media-vm -b
journalctl -u microvm@app-vm -b
```
```

- [ ] **Step 4: Re-run the docs grep**

Run:

```bash
rg -n "agenix|rsshub|ssh_host_ed25519_key|first boot|microvm@app-vm|inactive" docs/operations/secrets.md docs/operations/first-boot.md
```

Expected: PASS with matches for the secret model and bootstrap behavior.

- [ ] **Step 5: Commit**

```bash
git add docs/operations/secrets.md docs/operations/first-boot.md
git commit -m "docs: add secrets and first-boot guides"
```

## Task 5: Tighten `INSTALL.md` And Link To The Operations Docs

**Files:**
- Modify: `INSTALL.md`

- [ ] **Step 1: Write the failing link check**

Run:

```bash
rg -n "docs/operations/README.md|Operations Guide|Further Reading|Next Steps" INSTALL.md
```

Expected: FAIL because `INSTALL.md` does not yet link to the new operations area.

- [ ] **Step 2: Add a short next-steps section and trim extended operations prose**

Update `INSTALL.md` so it keeps installation steps and minimal validation intact, but replaces long-form operations explanation with a short handoff section near the end:

```markdown
## Next Steps

After installation, use the operations guide for ongoing system management:

- [`docs/operations/README.md`](./docs/operations/README.md)
- [`docs/operations/architecture-map.md`](./docs/operations/architecture-map.md)
- [`docs/operations/services.md`](./docs/operations/services.md)
- [`docs/operations/secrets.md`](./docs/operations/secrets.md)
- [`docs/operations/first-boot.md`](./docs/operations/first-boot.md)
```

Keep the installation procedure, reboot steps, and minimal first-boot validation commands. If the current `Application Tier Notes` section reads like architecture guidance rather than install guidance, move or compress it so `INSTALL.md` stays installation-focused.

- [ ] **Step 3: Re-run the link check**

Run:

```bash
rg -n "docs/operations/README.md|Operations Guide|Further Reading|Next Steps" INSTALL.md
```

Expected: PASS with matches in the new handoff section.

- [ ] **Step 4: Commit**

```bash
git add INSTALL.md
git commit -m "docs: link install guide to operations docs"
```

## Task 6: Verify The Documentation Set

**Files:**
- Verify only: `docs/operations/*.md`, `INSTALL.md`

- [ ] **Step 1: Verify all planned docs exist**

Run:

```bash
find docs/operations -maxdepth 1 -type f | sort
```

Expected:

```text
docs/operations/README.md
docs/operations/architecture-map.md
docs/operations/first-boot.md
docs/operations/secrets.md
docs/operations/services.md
```

- [ ] **Step 2: Verify the new docs cross-link correctly**

Run:

```bash
rg -n "architecture-map.md|services.md|secrets.md|first-boot.md|INSTALL.md" docs/operations/README.md
rg -n "docs/operations/README.md" INSTALL.md
```

Expected: PASS with links from the operations index and from `INSTALL.md`.

- [ ] **Step 3: Verify the main topics are covered**

Run:

```bash
rg -n "Host|storage-vm|media-vm|app-vm" docs/operations/architecture-map.md
rg -n "RSSHub|Media Stack|Storage Protocols" docs/operations/services.md
rg -n "Current Model|Bootstrap Expectations|Rotation And Updates" docs/operations/secrets.md
rg -n "Core Host Checks|MicroVM Checks|Expected Bootstrap-Safe States" docs/operations/first-boot.md
```

Expected: PASS for each grep with matches for the required sections.

- [ ] **Step 4: Review working tree state**

Run:

```bash
git status --short
```

Expected: only the intended documentation changes remain before final integration.

## Self-Review

Spec coverage:
- Dedicated `docs/operations/` area: Tasks 1 through 4
- Single entry point for operators: Task 1
- Architecture and configuration lookup guidance: Tasks 2 and 3
- Secret bootstrap guidance: Task 4
- First-boot behavior and expected inactive states: Task 4
- `INSTALL.md` boundary and handoff: Task 5

Placeholder scan:
- The plan uses concrete file paths, headings, and commands for every document.
- No task relies on undefined helper scripts or hidden structure.

Type consistency:
- The operations directory is always `docs/operations/`.
- Document names remain consistent across creation, linking, and verification steps.
