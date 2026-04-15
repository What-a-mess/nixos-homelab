# Edge Caddy

This guide covers the host public ingress layer built around Caddy and mTLS.

## Public Ingress Responsibilities

- Caddy is the host-facing TLS terminator and reverse proxy.
- It routes public hostnames to the VM backends defined in `lib/homelab-config.nix`.
- It enforces mTLS for all currently public sites.
- DDNS updates the Alibaba Cloud wildcard `AAAA` record for the configured edge domain.
- If the PKI files are missing, public ingress is unavailable by design.

## Domain And DDNS Inputs

The host-local edge domain settings live in `hosts/homelab/edge-local.nix`:

- `homelab.edge.domain`
- `homelab.edge.port`
- `homelab.edge.manageApex`

Current service hostnames come from `lib/homelab-config.nix` and resolve under the configured domain, for example:

- `rsshub.<domain>`
- `jellyfin.<domain>`
- `router.<domain>`

DDNS uses the encrypted `edge-aliyun.env.age` secret on the host. The decrypted env file must provide Alibaba Cloud DNS credentials as either:

- `ALICLOUD_ACCESS_KEY_ID` and `ALICLOUD_ACCESS_KEY_SECRET`
- or the legacy aliases `ALICLOUD_ACCESS_KEY` and `ALICLOUD_SECRET_KEY`

The DDNS service updates:

- `*.<domain>` `AAAA`
- optionally `<domain>` `AAAA` when `homelab.edge.manageApex = true`

## Host-Local PKI Layout

The host PKI lives under `/srv/data/edge/`:

- `/srv/data/edge/caddy/` - generated Caddy config and runtime inputs
- `/srv/data/edge/pki/server/` - server certificate material used by Caddy
- `/srv/data/edge/pki/client-ca/` - client CA used to verify device certificates
- `/srv/data/edge/pki/clients/` - per-device client certs and exported bundles

## Server Certificate Files

Caddy expects these server-side TLS files:

- `/srv/data/edge/pki/server/fullchain.pem`
- `/srv/data/edge/pki/server/privkey.pem`

## Client CA And Device Certificates

The client-auth flow is:

1. Create or update the client CA under `/srv/data/edge/pki/client-ca/`.
2. Issue one client certificate per device.
3. Export the device certificate, key, and CA bundle together for installation on the device.
4. Caddy validates the presented client certificate against the configured client CA.

Keep device certificates separate. Rotate a single device by replacing only that device's bundle.

## Export `.p12` Bundles

Use a PKCS#12 bundle when a client needs one portable import file:

```bash
openssl pkcs12 -export \
  -inkey <client.key> \
  -in <client.crt> \
  -certfile <client-ca.crt> \
  -out <device>.p12
```

Store the resulting bundle in `/srv/data/edge/pki/clients/` and distribute it to the target device through your normal secrets channel.

## Reload Caddy

Reload after changing the generated Caddy config or replacing certificate material:

```bash
sudo systemctl reload caddy
```

Check service state if the reload does not take effect:

```bash
systemctl status caddy.service
```

## Verify mTLS

Use the edge port and hostnames from the plan when validating public ingress:

```bash
systemctl status caddy.service edge-ddns.service edge-ddns.timer
journalctl -u edge-ddns.service -b
journalctl -u caddy.service -b
ss -ltnp | rg <edge-port>
curl -vk --resolve <host>:<port>:[<public-ipv6>] https://<host>:<port>/
curl -vk --resolve <host>:<port>:[<public-ipv6>] --cert <client.pem> --key <client.key> https://<host>:<port>/
openssl s_client -connect [<public-ipv6>]:<port> -servername <host> -cert <client.pem> -key <client.key>
```

Expected results:

- `ss` shows Caddy listening on the edge port.
- `edge-ddns.service` reports either a record create, a record update, or a no-op when the wildcard `AAAA` already matches the current public IPv6.
- The unauthenticated `curl` request fails the mTLS check.
- The authenticated `curl` request succeeds only when the request has the right hostname and a valid client certificate.
- `openssl s_client` completes the TLS handshake when the client certificate is accepted.
