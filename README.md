# tailscale-operator

Installs the [Tailscale Kubernetes Operator](https://tailscale.com/kb/1236/kubernetes-operator) on a homelab k3s cluster (OrbStack) via Helm. The operator provides `ingressClassName: tailscale`, which every other homelab app in this cluster depends on for its `*.stoat-perch.ts.net` hostname and auto-HTTPS.

## Depends on

- **A Tailscale account** with an OAuth client configured (see [Prerequisites](#prerequisites) below)
- **k3s / OrbStack** — the cluster must be running and `kubectl` pointing at it
- **Helm 3** — `brew install helm`

## Prerequisites

Before running `./deploy.sh` you need a Tailscale OAuth client:

1. Go to [https://login.tailscale.com/admin/settings/oauth](https://login.tailscale.com/admin/settings/oauth)
2. Create a new OAuth client with these scopes:
   - **Devices Core** — Read + Write
   - **Auth Keys** — Write
3. Set a tag (recommended: `tag:k8s-operator`). This tag must exist in your [ACL policy](https://login.tailscale.com/admin/acls) — add it under `tagOwners` if missing.
4. Copy the **Client ID** and **Client Secret** — you only see the secret once.

Without this, the operator cannot mint auth keys for new proxy pods and no Ingress will get a hostname.

## Quick start

```bash
git clone https://github.com/seenimurugan/tailscale-operator
cd tailscale-operator

# 1. Set env
cp .env.example .env
$EDITOR .env   # fill in TAILSCALE_OAUTH_CLIENT_ID and TAILSCALE_OAUTH_CLIENT_SECRET

# 2. Deploy
./deploy.sh
```

`deploy.sh` is idempotent — safe to re-run. It:
- Adds the Tailscale Helm repo
- Creates the `tailscale` namespace if needed
- Creates/updates the `operator-oauth` Secret
- Helm installs/upgrades the operator
- Verifies the `tailscale` IngressClass is registered

## Access

The operator has no UI. Manage via:

| | |
|---|---|
| **Tailscale admin console** | https://login.tailscale.com/admin |
| **Operator pod status** | `kubectl get pods -n tailscale` |
| **All ingresses** | `kubectl get ingress -A` |
| **Operator logs** | `kubectl logs -n tailscale -l app=operator --tail=30 -f` |

## Apps exposed by this operator

| App | Tailscale URL |
|---|---|
| Jellyfin | https://jellyfin.stoat-perch.ts.net |
| Immich | https://immich.stoat-perch.ts.net |
| Docs | https://docs.stoat-perch.ts.net |
| Grocy | https://grocy.stoat-perch.ts.net |
| Chores | https://chores.stoat-perch.ts.net |
| Reminders | https://reminders.stoat-perch.ts.net |

## Exposing a new app

Add an `Ingress` to the app's k8s manifest:

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
        - myapp   # subdomain only — operator appends .<tailnet>.ts.net
```

Wait ~30 s then check `kubectl get ingress myapp -n homelab` — `ADDRESS` will show `myapp.stoat-perch.ts.net`.

## Tear down

```bash
./undeploy.sh
```

> **Warning:** this removes ALL Tailscale ingress proxies — every app loses its hostname until the operator is reinstalled.

## Docs

- [docs/README.md](docs/README.md) — operator overview, access details
- [docs/USAGE.md](docs/USAGE.md) — connecting devices, exposing services, family sharing
- [docs/MAINTENANCE.md](docs/MAINTENANCE.md) — upgrade, OAuth rotation, troubleshooting
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — how the operator works, design decisions

Also rendered at https://docs.stoat-perch.ts.net (sidebar → homelab-k8s-setup → apps → tailscale).
