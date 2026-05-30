#!/usr/bin/env bash
# undeploy.sh — remove the Tailscale Kubernetes Operator
#
# WARNING: Uninstalling the operator removes ALL Tailscale Ingress proxies.
#          Every app using ingressClassName: tailscale will lose its hostname
#          until the operator is reinstalled and proxies are re-provisioned.
#
# The tailscale namespace is NOT deleted by default (see step 4 below).
# Deleting it also removes any per-Ingress proxy pods still running.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Load .env for NAMESPACE ───────────────────────────────────────────────────
ENV_FILE="$SCRIPT_DIR/.env"
if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  set -a; source "$ENV_FILE"; set +a
fi
NAMESPACE="${HOMELAB_NAMESPACE:-tailscale}"

echo "Undeploying Tailscale Operator from namespace '$NAMESPACE'..."
echo ""
echo "  WARNING: ALL apps using ingressClassName: tailscale will lose connectivity"
echo "           until the operator is reinstalled (./deploy.sh)."
echo ""

# ── 1. Helm uninstall ─────────────────────────────────────────────────────────
echo "Step 1: Removing helm release tailscale-operator..."
if helm status tailscale-operator -n "$NAMESPACE" &>/dev/null; then
  helm uninstall tailscale-operator -n "$NAMESPACE"
else
  echo "  Helm release not found — skipping."
fi

# ── 2. Delete OAuth secret ────────────────────────────────────────────────────
echo "Step 2: Deleting operator-oauth secret..."
kubectl delete secret operator-oauth -n "$NAMESPACE" --ignore-not-found

# ── 3. Confirm operator pods are gone ─────────────────────────────────────────
echo "Step 3: Remaining pods in '$NAMESPACE' namespace:"
kubectl get pods -n "$NAMESPACE" 2>/dev/null || echo "  (namespace may already be empty)"

# ── 4. Optionally delete the namespace ───────────────────────────────────────
echo ""
echo "Step 4 (OPTIONAL — namespace deletion)"
echo "  The '$NAMESPACE' namespace still exists with any leftover proxy pods."
echo "  To fully remove it:"
echo ""
echo "    kubectl delete namespace $NAMESPACE"
echo ""
echo "  DANGER: This also removes any CRDs, proxy pods, and other resources"
echo "          the operator created. Only do this on a full reinstall."
echo ""
echo "Done. To reinstall: ./deploy.sh"
