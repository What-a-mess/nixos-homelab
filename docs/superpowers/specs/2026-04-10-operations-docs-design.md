# Operations Documentation Design

Date: 2026-04-10

## Summary

This document defines a dedicated operations documentation area for the homelab repository so installation steps, system structure, service configuration locations, and secret-management procedures are documented in one coherent place.

The chosen direction is:
- Keep `INSTALL.md` focused on installation and minimal first-boot validation.
- Add a dedicated `docs/operations/` area for post-install operations guidance.
- Organize the operations docs by operator task rather than by repository directory alone.
- Make special configuration areas, including secrets and service placement, easy to discover from a single index page.

## Goals

- Provide a clear post-install entry point for understanding and operating the homelab.
- Document where each major system area is configured.
- Document how special components such as RSSHub secrets are configured and bootstrapped.
- Prevent `INSTALL.md` from becoming a mixed install-plus-operations handbook.
- Establish a repeatable documentation structure for future services and infrastructure changes.

## Non-Goals

- Replacing historical design material in `openspec/`.
- Duplicating every implementation detail from code into prose.
- Creating an exhaustive troubleshooting manual for every possible failure.
- Reorganizing code purely to match documentation categories.

## Current Context

The repository currently has:
- `INSTALL.md` for installation and first-boot checks.
- `openspec/` for design history and change records.
- `docs/superpowers/specs/` and `docs/superpowers/plans/` for in-progress design and planning artifacts.

The repository does not currently have:
- A dedicated operator-facing documentation area for configuration lookup and ongoing system management.
- A single page that answers "where is this configured?"
- A stable home for secret bootstrap instructions outside of design docs and plans.

## Chosen Approach

The repository will introduce a new documentation area:

- `docs/operations/README.md`
- `docs/operations/architecture-map.md`
- `docs/operations/services.md`
- `docs/operations/secrets.md`
- `docs/operations/first-boot.md`

This structure is preferred over expanding `INSTALL.md` because install instructions and operational reference material evolve at different speeds and serve different user needs.

## Documentation Architecture

### 1. `docs/operations/README.md`

This file is the navigation entry point.

It should answer:
- Where do I start after installation?
- Which document should I read to find a service config?
- Where are secrets explained?
- Where do I look for first-boot validation?

It should be organized by operator intent, for example:
- Understand system structure
- Find where a service is configured
- Configure secrets
- Validate first boot

It should remain short and link-heavy rather than becoming a long-form technical document.

### 2. `docs/operations/architecture-map.md`

This file explains system boundaries and where those boundaries are represented in the repository.

It should cover:
- Host responsibilities
- `storage-vm` responsibilities
- `media-vm` responsibilities
- `app-vm` responsibilities
- The role of `hosts/`, `modules/`, `vms/`, `lib/`, and `secrets/`

It should emphasize configuration entry points, such as:
- Host composition in `hosts/homelab/default.nix`
- Shared constants in `lib/homelab-config.nix`
- Service-group VM entrypoints in `vms/*.nix`
- Per-tier implementation modules in `modules/**`

### 3. `docs/operations/services.md`

This file documents where major services live and which files control them.

It should cover current services and their boundaries, including:
- RSSHub in `app-vm`
- Media stack services in `media-vm`
- Storage protocols in `storage-vm`

Each service section should answer:
- Which VM or host boundary owns the service
- Which files define the entrypoint
- Which files define runtime behavior
- Which shared config values affect it

This document should act as the main "where is this configured?" reference for workloads.

### 4. `docs/operations/secrets.md`

This file is the operator-facing secret-management guide.

It should explain:
- The current secret-management model
- Which files declare encrypted secrets
- Which module handles host-side decryption
- How bootstrap works after first installation
- Why a service may remain inactive when its secret is absent

It should explicitly cover the RSSHub secret workflow and identify the relevant repository paths.

This document is the correct home for details that do not belong in `INSTALL.md`, such as host identity enrollment and secret rotation expectations.

### 5. `docs/operations/first-boot.md`

This file explains what to check after installation and how to interpret expected bootstrap states.

It should cover:
- Core host validation
- MicroVM status checks
- Service reachability checks
- Expected first-boot conditions, including secret-gated services that may be inactive until configured

This document should keep a strict focus on post-install validation rather than broader architecture explanation.

## Boundary With `INSTALL.md`

`INSTALL.md` should remain responsible for:
- Machine prerequisites
- Disk preparation and mounting
- Hardware config generation
- Repository copy or clone
- `nixos-install`
- Reboot
- Minimal first-boot validation commands

Operational topics should move to `docs/operations/`, including:
- Service placement rationale
- Secret bootstrap details
- Configuration lookup guidance
- Extended first-boot interpretation

`INSTALL.md` may include a short "next steps" or "further reading" section that links to `docs/operations/README.md`, but it should not absorb detailed operational guidance.

## Writing Rules

The operations docs should follow these rules:

- Organize by operator task, not by implementation history.
- Prefer explicit repository paths over abstract descriptions.
- Distinguish clearly between current behavior and planned or incomplete work.
- Document bootstrap-safe inactive states as expected behavior where applicable.
- Keep index pages short and delegate detail to topic pages.

## Maintenance Rules

To prevent the documentation from drifting again, repository changes should follow these update rules:

- Adding a new service or changing service placement must update `docs/operations/services.md`.
- Changing secret-management flow must update `docs/operations/secrets.md`.
- Changing system boundaries or repository entrypoints must update `docs/operations/architecture-map.md`.
- Changing first-boot expectations must update `docs/operations/first-boot.md`.
- `docs/operations/README.md` must be updated whenever a new operations topic becomes relevant to operators.

## Tradeoffs and Rationale

### Why Not Expand `INSTALL.md`

Extending `INSTALL.md` further would mix:
- one-time installation steps
- post-install operating guidance
- system structure explanation
- special-case bootstrap behavior

That would make the document harder to scan and harder to maintain.

### Why Not Use A Single Operations Document

A single document would initially be faster to create, but it would quickly become a grab-bag of unrelated material. The proposed split keeps navigation, structure, services, secrets, and validation separated by responsibility.

### Why Keep `openspec/` Separate

`openspec/` captures design and change history. The new `docs/operations/` area is for current operator guidance. Mixing them would blur historical rationale with present-day instructions.

## Acceptance Criteria

- The repository has a dedicated `docs/operations/` area for operator-facing guidance.
- Operators can quickly find where major services and special components are configured.
- Secret configuration and bootstrap instructions have a stable home outside design and planning artifacts.
- `INSTALL.md` remains focused on installation and minimal first-boot validation.
- The documentation structure is clear enough to extend as new homelab services are added.
