# Tailscale Operator

The Tailscale Kubernetes Operator gives every cluster Ingress its own `*.stoat-perch.ts.net` hostname with auto-HTTPS, reachable from any Tailscale device.

## Access

The operator itself doesn't have a UI — manage via:

| Where | URL/CLI |
|---|---|
| **Tailscale admin console (machines, ACLs, OAuth)** | https://login.tailscale.com/admin |
| **From this Mac (operator status)** | `kubectl get pods,ingress -n tailscale` |

The apps it exposes:

| App | Tailscale URL |
|---|---|
| Jellyfin | https://jellyfin.stoat-perch.ts.net |
| Immich | https://immich.stoat-perch.ts.net |
| Docs | https://docs.stoat-perch.ts.net |
| Grocy | https://grocy.stoat-perch.ts.net |
| Email matrix | https://emailmatrix.stoat-perch.ts.net |
| Chores | https://chores.stoat-perch.ts.net |

## Detailed docs

- [📋 USAGE](USAGE.md) — connect new devices, expose new services, share with family
- [🛠 MAINTENANCE](MAINTENANCE.md) — install, upgrade, OAuth rotation, troubleshooting
- [🏛 ARCHITECTURE](ARCHITECTURE.md) — how the operator works, design decisions
