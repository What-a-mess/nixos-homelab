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
systemctl status microvm@router-vm
```

These checks confirm that the service-group VMs started correctly.

## Service Reachability

Run:

```bash
ping -c 1 192.168.31.211
ping -c 1 192.168.31.212
ping -c 1 192.168.31.213
ping -c 1 192.168.31.214
curl -I http://192.168.31.213:1200
```

If the bridge and guest addressing are correct, the pings should succeed.
If RSSHub is fully configured, the HTTP probe should return a response from `app-vm`.
If it does not, distinguish between two bootstrap states:

- The secret is not enrolled yet, so the service is still waiting on its encrypted payload
- The secret flow is not fully wired yet, so the host can boot but RSSHub still cannot become healthy

## Expected Bootstrap-Safe States

During early bootstrap, some conditions are expected:

- `app-vm` may be running even if RSSHub is not yet usable
- RSSHub may remain inactive if its secret has not been enrolled yet
- RSSHub may also remain inactive if the secret flow is not fully wired yet
- `router-vm` may be running even if `mihomo` is inactive because `/srv/data/router/mihomo/config.yaml` has not been created yet
- The VMs should still retain their fixed LAN addresses even when an application inside them is inactive
- Secret-gated service inactivity should be interpreted in the context of bootstrap state, not automatically as a host installation failure

## If A VM Fails To Start

Inspect:

```bash
journalctl -u microvm@storage-vm -b
journalctl -u microvm@media-vm -b
journalctl -u microvm@app-vm -b
journalctl -u microvm@router-vm -b
```
