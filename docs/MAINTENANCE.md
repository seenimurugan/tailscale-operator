# Tailscale Operator — Maintenance

**On this page:** [Deploy / upgrade](#deploy--upgrade) · [Restart operator](#restart-operator) · [Restart a specific Ingress's proxy pod](#restart-a-specific-ingresss-proxy-pod) · [View operator logs](#view-operator-logs) · [Rotate OAuth credentials](#rotate-oauth-credentials) · [Troubleshooting](#troubleshooting)

## Deploy / upgrade

```bash
helm repo update tailscale
helm upgrade tailscale-operator tailscale/tailscale-operator \
  --namespace tailscale --reuse-values
```

Initial install (not needed unless wiping and starting over):
```zsh
# Get OAuth creds from https://login.tailscale.com/admin/settings/oauth
# (scopes: Devices Core Write + Auth Keys Write; tag: tag:k8s-operator)
read -s "TS_ID?Client ID: "; echo
read -s "TS_SECRET?Client Secret: "; echo

helm install tailscale-operator tailscale/tailscale-operator \
  --namespace tailscale --create-namespace \
  --set-string oauth.clientId="$TS_ID" \
  --set-string oauth.clientSecret="$TS_SECRET" \
  --set apiServerProxyConfig.mode=true
unset TS_ID TS_SECRET
```

⚠️ Use **zsh syntax** (`read -s "VAR?Prompt: "`). bash's `-p` flag doesn't work in zsh and silently sets empty values. See [learnings.md](../../learnings.md).

## Restart operator
```bash
kubectl rollout restart deployment/operator -n tailscale
```

## Restart a specific Ingress's proxy pod
```bash
# Find the proxy pod
kubectl get pods -n tailscale

# Delete it (operator recreates)
kubectl delete pod -n tailscale ts-jellyfin-xxxxx-0
```

## View operator logs
```bash
kubectl logs -n tailscale -l app=operator --tail=30 -f
```

## Rotate OAuth credentials

If credentials are compromised (e.g. accidentally pasted in chat):

1. Revoke + generate new at https://login.tailscale.com/admin/settings/oauth
2. In **your terminal** (not in Claude — would leak again):
   ```zsh
   read -s "TS_ID?Client ID: "; echo
   read -s "TS_SECRET?Client Secret: "; echo
   helm upgrade tailscale-operator tailscale/tailscale-operator \
     --namespace tailscale --reuse-values \
     --set-string oauth.clientId="$TS_ID" \
     --set-string oauth.clientSecret="$TS_SECRET"
   unset TS_ID TS_SECRET
   kubectl rollout restart deployment/operator -n tailscale
   ```

## Troubleshooting

### Tailscale URLs return 000 or connection refused
1. `kubectl get pods -n tailscale` (operator must be 1/1)
2. `kubectl get ingress <name> -n homelab` (ADDRESS should show `<name>.<tailnet>.ts.net`)
3. From phone: check Tailscale app shows the homelab device in the device list

### New Ingress not getting a hostname
```bash
kubectl describe ingress <name> -n homelab
kubectl logs -n tailscale -l app=operator --tail=30
```
Common causes:
- OAuth credentials revoked/expired/empty
- ACL policy doesn't allow `tag:k8s` (the tag the operator assigns to proxies)

### Operator pod CrashLoopBackOff
Check logs. Most likely empty OAuth credentials in the `operator-oauth` Secret. See [learnings.md](../../learnings.md) for the gotcha where empty values from zsh's broken `read -p` lead to silent breakage.

### Want to remove an Ingress
```bash
kubectl delete ingress <name> -n homelab
```
Operator deletes the corresponding proxy pod and removes the hostname from your tailnet.
