# RSSHub Secret Management Design

Date: 2026-04-09

## Summary

This document defines how the homelab manages RSSHub authentication secrets for services such as X while preserving the repository's declarative deployment model.

The chosen direction is:
- Use `agenix` for repository-managed encrypted secrets.
- Use the homelab host SSH host key as the decryption identity.
- Decrypt on the host, not inside `app-vm`.
- Keep `app-vm` and RSSHub deployable even when the secret is not present.
- Treat missing secrets during first deployment as expected bootstrap state rather than as a deployment failure.

## Goals

- Keep RSSHub tokens out of `.nix` source files and out of plaintext Git history.
- Preserve a declarative, reproducible deployment model for secret-backed services.
- Allow first deployment of the host and `app-vm` before RSSHub secrets have been added to the repository.
- Avoid introducing a manual `enable` flag solely for bootstrap sequencing.
- Establish a reusable secret-management pattern for future app services.

## Non-Goals

- General multi-host secret orchestration.
- Per-VM decryption identities.
- A generic secret UI or out-of-band secret management platform.
- Solving application-level token validity or rate-limit issues for RSSHub routes.

## Current Context

The repository already defines:
- A dedicated `app-vm` execution boundary for RSSHub.
- Podman-based OCI container deployment for RSSHub inside `app-vm`.
- A single-host homelab topology.

The repository does not currently define:
- A secret-management layer such as `agenix` or `sops-nix`.
- A runtime path for secret-backed environment files for RSSHub.
- Bootstrap behavior for services whose runtime configuration depends on secrets.

## Chosen Approach

The system will adopt `agenix` as the first secret-management layer for application tokens.

Secret ownership and flow will be:
1. The host owns the decryption identity.
2. The repository stores encrypted secret files only.
3. The host decrypts those files into runtime-only paths during deployment.
4. RSSHub consumes the resulting runtime environment file.
5. If the expected secret file is absent, RSSHub is skipped rather than treated as a fatal system deployment error.

This approach is preferred over `sops-nix` because the current scope is a single host and a small number of application secrets. It is preferred over repository-external plaintext files because the repository should remain the source of truth for deployable infrastructure state.

## Architecture

### Trust Boundary

The host is the only decryption boundary.

Implications:
- The host SSH host key is the root identity for decrypting RSSHub secrets.
- `app-vm` does not receive a separate decryption identity.
- RSSHub receives plaintext secrets only as runtime input.
- The repository remains safe to share as long as only encrypted secret artifacts are committed.

This keeps the secret model aligned with the current architecture, where the host orchestrates microVMs and application service boundaries.

### Repository Layout

The repository should introduce a structure equivalent to:

- `secrets/`
- `secrets/secrets.nix`
- `secrets/rsshub.env.age`
- `docs/superpowers/specs/2026-04-09-rsshub-secret-management-design.md`

The encrypted RSSHub secret file should contain environment-variable style content suitable for direct container consumption.

Plaintext secret files must not be committed. Repository ignore rules should exclude temporary plaintext `.env` or equivalent local secret staging files.

### Runtime Secret Delivery

At deployment time:
1. `agenix` decrypts `secrets/rsshub.env.age` on the host.
2. The decrypted file is materialized into a runtime-only path.
3. RSSHub reads the decrypted environment file through its container runtime configuration.

The final runtime injection mechanism should preserve the current declarative Podman-based RSSHub deployment shape rather than replacing it with imperative post-start scripting.

## Bootstrap and First Deployment

### Two-Phase Bootstrap

Initial rollout should explicitly support two deployments.

Phase 1:
- Deploy the host, microVMs, and RSSHub service definitions from the repository.
- Allow RSSHub to remain inactive because the encrypted secret has not yet been added.

Phase 2:
- Read the host SSH public key from the newly installed host.
- Convert that identity into an `age` recipient on the management machine.
- Create the RSSHub plaintext environment content on the management machine.
- Encrypt it into `secrets/rsshub.env.age`.
- Commit the encrypted file to Git.
- Redeploy the host.
- Allow RSSHub to start automatically once the secret is available.

This avoids maintaining a separate bootstrap configuration and avoids introducing a dedicated feature flag for first deployment.

### Manual Operator Actions

The bootstrap process requires limited manual work.

On the host:
- Read the host SSH public key after initial installation.

On the management machine:
- Maintain `agenix` tooling.
- Register the host recipient.
- Create and edit the RSSHub plaintext secret content.
- Save the encrypted secret artifact into the repository.

The operator should not need to manually log into `app-vm` or edit RSSHub runtime state inside the VM.

## Service Behavior

### Missing Secret

Missing secret material must be treated as valid bootstrap state.

Expected behavior:
- Host deployment succeeds.
- `app-vm` deployment succeeds.
- RSSHub does not enter active service.
- The absence of the secret does not invalidate unrelated workloads.

The intended operational model is "service skipped until secret exists," not "service hard-fails and drags deployment into a broken state."

### Present but Invalid Secret

If the secret file exists but contains invalid or expired credentials:
- RSSHub may still start.
- Route-level access to upstream services may fail.
- This must be treated as application configuration failure, not infrastructure bootstrap failure.

### Decryption Failure

If decryption fails because the host identity is wrong or recipient configuration is stale:
- The runtime secret file is not produced.
- RSSHub falls back to missing-secret behavior.
- The failure should be diagnosable from deployment logs and secret materialization state.

## Operations

### Secret Rotation

Secret rotation should follow the same path as first creation:
1. Edit plaintext content on the management machine.
2. Re-encrypt the repository secret artifact.
3. Commit the updated encrypted file.
4. Redeploy the host.

No manual edits inside `app-vm` should be required.

### Host Identity Continuity

The host SSH host key is now part of the secret recovery model.

Operational consequence:
- If the host key changes, existing encrypted secrets must be re-encrypted to the new recipient before they can be consumed again.

This is acceptable for the current single-host homelab scope, but it must be documented because host-key replacement becomes a secret-operations event.

## Tradeoffs and Rationale

### Why `agenix`

`agenix` is the recommended first step because:
- The current environment is single-host.
- The expected secret set is still small.
- The trust model can reuse the host SSH identity.
- It adds less structure than `sops-nix` while still keeping encrypted artifacts in Git.

### Why Host Decryption Instead of VM Decryption

Host-side decryption is preferred because:
- The host already owns infrastructure orchestration.
- Secret boundaries remain centralized.
- `app-vm` does not need extra identity provisioning.
- Bootstrap and debugging remain simpler.

### Why Skip Instead of Require an Explicit Enable Flag

Skipping is preferred because:
- The repository already models integrated deployment.
- The operator wants minimal bootstrap friction.
- Missing-secret state is a natural prerequisite condition, not a user-facing feature toggle.

## Future Extension

The same pattern can later be reused for:
- Other RSSHub upstream credentials.
- Additional app-tier services in `app-vm`.
- Host-level service credentials such as API tokens, if needed.

If the homelab later expands to multiple hosts or many distinct secret classes, reevaluating `sops-nix` may become worthwhile. That is not necessary for the current design.

## Acceptance Criteria

- The repository can store encrypted RSSHub secrets without storing plaintext tokens.
- A first deployment can complete without RSSHub secrets being present.
- RSSHub remains inactive rather than causing system-wide deployment failure when its secret is absent.
- Adding the encrypted secret and redeploying is sufficient to make RSSHub consumable without manual VM-side configuration.
- The design establishes a repeatable pattern for future secret-backed app services.
