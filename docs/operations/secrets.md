# Secrets

This document explains how encrypted secrets are managed for the homelab.

## Current Model

The current design uses host-side decryption for application secrets.

- Encrypted secret declarations live in [`secrets/`](../../secrets)
- Host-side secret handling is implemented in [`modules/host/secrets.nix`](../../modules/host/secrets.nix)
- Shared secret metadata and shared VM path conventions live in [`lib/homelab-config.nix`](../../lib/homelab-config.nix)

## Current Repo Caveats

The repository still has bootstrap gaps that matter operationally:

- There is no committed [`secrets/rsshub.env.age`](../../secrets/rsshub.env.age) payload yet
- [`secrets/secrets.nix`](../../secrets/secrets.nix) still contains a placeholder recipient

## RSSHub Secret Flow

RSSHub secrets are intended to follow this target design:

1. The host owns the decryption identity.
2. The repository stores encrypted secret artifacts.
3. The host decrypts the secret into a runtime path.
4. In the completed design, `app-vm` consumes the runtime secret file for RSSHub.

This flow is the intended end state. In the current repo state, it is not yet fully wired end to end.

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

Until the encrypted secret exists and the flow is fully wired, RSSHub may remain inactive. That is expected bootstrap behavior.

## Rotation And Updates

When a secret changes:

1. Update the encrypted secret artifact.
2. Rebuild the host.
3. Verify the host and `app-vm` consume the updated runtime file.

Plaintext secret staging files should not be committed.
