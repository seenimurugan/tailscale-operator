# Tailscale Operator

The Tailscale Kubernetes Operator gives every cluster Ingress its own `*.stoat-perch.ts.net` hostname with auto-HTTPS, reachable from any Tailscale device. It is not an app with a UI — it is infrastructure that makes every other app's Tailnet URL work.

Source: Helm chart `tailscale/tailscale-operator` (no custom code). Managed at `/Users/nila/Developer/apps/tailscale-operator/`.

---

## Access

The operator itself has no web UI. Manage via:

| Where | URL / CLI |
|---|---|
| **Tailscale admin console** (machines, ACLs, OAuth) | https://login.tailscale.com/admin |
| **Operator status from this Mac** | `kubectl get pods,ingress -n tailscale` |
| **List all active Ingresses** | `kubectl get ingress -n homelab` |

---

## Apps exposed via this operator

| App | Tailnet URL |
|---|---|
| Jellyfin | https://jellyfin.stoat-perch.ts.net |
| Immich | https://immich.stoat-perch.ts.net |
| Docs | https://docs.stoat-perch.ts.net |
| Grocy | https://grocy.stoat-perch.ts.net |
| FileBrowser | https://files.stoat-perch.ts.net |
| Chores | https://chores.stoat-perch.ts.net |
| Reminders | https://reminders.stoat-perch.ts.net |
| Storage Console | https://tier.stoat-perch.ts.net |
| Email Matrix | https://emailmatrix.stoat-perch.ts.net |
| Moviesda | https://movies.stoat-perch.ts.net |
| Radarr | https://radarr.stoat-perch.ts.net |
| Prowlarr | https://prowlarr.stoat-perch.ts.net |
| qBittorrent | https://qbittorrent.stoat-perch.ts.net |
| Bazarr | https://bazarr.stoat-perch.ts.net |
| Grafana (monitoring) | https://grafana.stoat-perch.ts.net |

---

## What it does

- Watches for `Ingress` resources with `ingressClassName: tailscale` in any namespace.
- For each such Ingress, mints a Tailscale auth key (via OAuth) and spawns a small proxy pod that joins the tailnet.
- Auto-provisions an HTTPS cert for the hostname (no manual Let's Encrypt setup).
- Routes inbound Tailscale traffic → proxy pod → in-cluster Service → app pod.

---

## Stack & framework

| Layer | Tech |
|---|---|
| Operator | `tailscale/k8s-operator` (Go), installed via Helm |
| Chart | `tailscale/tailscale-operator` v1.98.x |
| Proxy pods | `tailscale/tailscale` (one per Ingress, in `tailscale` namespace) |
| Auth | OAuth client with `devices:write` + `auth_keys:write` scopes |
| HTTPS | Tailscale-issued certs (Let's Encrypt-style, automatic) |
| Cluster | k3s in OrbStack |

---

## Storage

Stateless — no PVCs. OAuth credentials stored in Secret `operator-oauth` in the `tailscale` namespace.

---

## See also

- [Usage guide](USAGE.md) — connect new devices, expose new services, share with family
- [Maintenance](MAINTENANCE.md) — install, upgrade, OAuth rotation, troubleshooting
- [Architecture](ARCHITECTURE.md) — how the operator works, design decisions
