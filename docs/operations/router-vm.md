# Router VM

This document explains how to operate `router-vm`.

## Responsibilities

`router-vm` provides:

- A route-node workflow for clients that set their default gateway to `192.168.31.214`
- Ordinary `http` and `socks5` proxy entrypoints
- A dedicated `mihomo` runtime boundary

## Local Config Placement

The real `mihomo` config is stored on the host at:

- `/srv/data/router/mihomo/config.yaml`

That directory is mounted into the guest at:

- `/var/lib/router-vm/mihomo-config`

## Bootstrap Behavior

If `config.yaml` does not exist yet:

- `router-vm` should still boot
- `mihomo` should remain inactive

This is expected bootstrap state.

## Operator Workflow

1. Deploy the host and `router-vm`.
2. Confirm that `router-vm` is reachable at `192.168.31.214`.
3. Place a valid `mihomo` config at `/srv/data/router/mihomo/config.yaml`.
4. Restart `mihomo` inside `router-vm` or rebuild the host.
5. Point a test client at `192.168.31.214` either as default gateway or proxy endpoint.
