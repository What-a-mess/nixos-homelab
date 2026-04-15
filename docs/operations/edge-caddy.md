# Edge Caddy

This guide covers the host public ingress layer built around Caddy and mTLS.

## Public Ingress Responsibilities

- Caddy is the host-facing TLS terminator and reverse proxy.
- It routes public hostnames to the VM backends defined in `lib/homelab-config.nix`.
- It enforces mTLS for all currently public sites.
- DDNS still publishes the host address; Caddy handles request admission.
- If the PKI files are missing, public ingress is unavailable by design.

## Host-Local PKI Layout

The host PKI lives under `/srv/data/edge/`:

- `/srv/data/edge/caddy/` - generated Caddy config and runtime inputs
- `/srv/data/edge/pki/server/` - server certificate material used by Caddy
- `/srv/data/edge/pki/client-ca/` - client CA used to verify device certificates
- `/srv/data/edge/pki/clients/` - per-device client certs and exported bundles

## Server Certificate Files

Caddy expects the server-side TLS files to be present under the server PKI directory and readable by the service:

- server certificate
- server private key
- any chain or fullchain material required by the generated Caddy config

The exact filenames are intentionally host-local and should stay aligned with the edge module and the generated Caddyfile.

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
journalctl -u caddy.service -b
ss -ltnp | rg <edge-port>
curl -vk --resolve <host>:<port>:[<public-ipv6>] --cert <client.pem> --key <client.key> https://<host>:<port>/
openssl s_client -connect [<public-ipv6>]:<port> -servername <host> -cert <client.pem> -key <client.key>
```

Expected results:

- `ss` shows Caddy listening on the edge port.
- `curl` succeeds only when the request has the right hostname and a valid client certificate.
- `openssl s_client` completes the TLS handshake when the client certificate is accepted.
