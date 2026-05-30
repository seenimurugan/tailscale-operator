#!/usr/bin/env bash
# deploy.sh — idempotent install/upgrade of the Tailscale Kubernetes Operator
# Usage: ./deploy.sh
# Safe to re-run — creates/updates the OAuth secret and helm-upgrades the chart.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── 1. Load .env ──────────────────────────────────────────────────────────────
ENV_FILE="$SCRIPT_DIR/.env"
if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERROR: .env not found."
  echo "       Copy .env.example to .env and fill in real values, then re-run."
  echo "         cp .env.example .env && \$EDITOR .env"
  exit 1
fi
# shellcheck disable=SC1090
set -a; source "$ENV_FILE"; set +a

# ── 2. Validate required env vars ─────────────────────────────────────────────
if [[ -z "${TAILSCALE_OAUTH_CLIENT_ID:-}" ]]; then
  echo "ERROR: TAILSCALE_OAUTH_CLIENT_ID is not set in .env"
  echo "       Create an OAuth client at https://login.tailscale.com/admin/settings/oauth"
  echo "       Required scopes: Devices Core (read+write), Auth Keys (write)"
  exit 1
fi
if [[ -z "${TAILSCALE_OAUTH_CLIENT_SECRET:-}" ]]; then
  echo "ERROR: TAILSCALE_OAUTH_CLIENT_SECRET is not set in .env"
  exit 1
fi

NAMESPACE="${HOMELAB_NAMESPACE:-tailscale}"

# ── 3. Prereq checks ──────────────────────────────────────────────────────────
for cmd in kubectl helm; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "ERROR: '$cmd' not found in PATH."
    exit 1
  fi
done
if ! kubectl cluster-info &>/dev/null; then
  echo "ERROR: Cannot reach the Kubernetes cluster. Is OrbStack running?"
  exit 1
fi

# ── 4. Add / update the Tailscale Helm repo ───────────────────────────────────
echo "Adding/updating tailscale Helm repo..."
helm repo add tailscale https://pkgs.tailscale.com/helmcharts 2>/dev/null || true
helm repo update tailscale

# ── 5. Ensure namespace exists ────────────────────────────────────────────────
if ! kubectl get namespace "$NAMESPACE" &>/dev/null; then
  echo "Namespace '$NAMESPACE' not found — creating it."
  kubectl create namespace "$NAMESPACE"
else
  echo "Namespace '$NAMESPACE' already exists."
fi

# ── 6. Create / update the operator-oauth Secret ──────────────────────────────
echo "Ensuring operator-oauth secret in namespace '$NAMESPACE'..."
kubectl create secret generic operator-oauth \
  -n "$NAMESPACE" \
  --from-literal=client_id="${TAILSCALE_OAUTH_CLIENT_ID}" \
  --from-literal=client_secret="${TAILSCALE_OAUTH_CLIENT_SECRET}" \
  --dry-run=client -o yaml | kubectl apply -f -

# ── 7. Helm install / upgrade ─────────────────────────────────────────────────
echo "Running helm upgrade --install tailscale-operator..."
helm upgrade --install tailscale-operator tailscale/tailscale-operator \
  --namespace "$NAMESPACE" \
  --set-string oauth.clientId="${TAILSCALE_OAUTH_CLIENT_ID}" \
  --set-string oauth.clientSecret="${TAILSCALE_OAUTH_CLIENT_SECRET}" \
  -f "$SCRIPT_DIR/values/operator-values.yaml" \
  --wait

# ── 8. Verify IngressClass was registered ─────────────────────────────────────
echo "Verifying tailscale IngressClass..."
if kubectl get ingressclass tailscale &>/dev/null; then
  echo ""
  echo "  IngressClass 'tailscale' is registered:"
  kubectl get ingressclass tailscale
else
  echo "WARNING: IngressClass 'tailscale' not found — check operator logs:"
  echo "  kubectl logs -n $NAMESPACE -l app=operator --tail=40"
  exit 1
fi

# ── 9. Done ───────────────────────────────────────────────────────────────────
echo ""
echo "Operator ready. Other apps can now use \`ingressClassName: tailscale\`."
echo ""
echo "  Operator status:   kubectl get pods -n $NAMESPACE"
echo "  Operator logs:     kubectl logs -n $NAMESPACE -l app=operator --tail=30 -f"
echo "  All ingresses:     kubectl get ingress -A"
echo "  Tailscale admin:   https://login.tailscale.com/admin/machines"
