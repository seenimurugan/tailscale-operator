# Tailscale Operator — Usage

How to expose new services and connect devices.

**On this page:** [Connect a device to your tailnet](#connect-a-device-to-your-tailnet) · [Expose a new cluster service](#expose-a-new-cluster-service) · [List all currently exposed services](#list-all-currently-exposed-services) · [Check which devices are on the tailnet](#check-which-devices-are-on-the-tailnet) · [Share an Ingress URL with family](#share-an-ingress-url-with-family)

## Connect a device to your tailnet

### iPhone / iPad
1. App Store → install **Tailscale**
2. Sign in (Google/Microsoft/Apple SSO, or email)
3. Done — phone is on the tailnet, can reach `*.stoat-perch.ts.net` URLs

### Mac
Install Tailscale.app from https://tailscale.com/download/mac.

### Android TV (Philips, etc.)
Play Store → Tailscale → install → scan QR with phone to sign in.

### Family member's phone
Tailnet admin → Users → **Invite** → enter their email → they install Tailscale and sign in.

## Expose a new cluster service

Add a `Ingress` with `ingressClassName: tailscale` to its k8s manifest:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp
  namespace: homelab
spec:
  ingressClassName: tailscale
  defaultBackend:
    service:
      name: myapp
      port:
        number: 80
  tls:
    - hosts:
        - myapp   # subdomain only — operator appends .stoat-perch.ts.net
```

Apply → wait ~30s → check:
```bash
kubectl get ingress myapp -n homelab   # ADDRESS shows myapp.stoat-perch.ts.net
```

The URL `https://myapp.stoat-perch.ts.net` is now reachable from any device on the tailnet.

See [ADD-NEW-APP](../../ADD-NEW-APP.md) for the full pattern.

## List all currently exposed services

```bash
kubectl get ingress -n homelab
```

## Check which devices are on the tailnet

Either:
- Open the Tailscale admin console: https://login.tailscale.com/admin/machines
- Or from any device with Tailscale CLI: `tailscale status`

You should see:
- The personal devices (iPhone, etc.)
- Tagged devices: `tailscale-operator`, `ts-jellyfin`, `ts-immich`, `ts-docs`, `ts-grocy`, `ts-emailmatrix`

## Share an Ingress URL with family

The Tailscale URLs only work for tailnet members. To share with someone NOT on your tailnet:

- **Invite them as a user**: admin console → Users → Invite by email. Free tier supports up to 100 users.
- **Or use Immich's share links / Jellyfin's "anonymous" mode** — those don't require Tailscale on the viewer's device.
