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
If it does not, distinguish between two bootstrap states:

- The secret is not enrolled yet, so the service is still waiting on its encrypted payload
- The secret flow is not fully wired yet, so the host can boot but RSSHub still cannot become healthy

## Expected Bootstrap-Safe States

During early bootstrap, some conditions are expected:

- `app-vm` may be running even if RSSHub is not yet usable
- RSSHub may remain inactive if its secret has not been enrolled yet
- RSSHub may also remain inactive if the secret flow is not fully wired yet
- Secret-gated service inactivity should be interpreted in the context of bootstrap state, not automatically as a host installation failure

## If A VM Fails To Start

Inspect:

```bash
journalctl -u microvm@storage-vm -b
journalctl -u microvm@media-vm -b
journalctl -u microvm@app-vm -b
```
