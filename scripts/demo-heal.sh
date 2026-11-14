#!/usr/bin/env bash
# Show ReplicaSet self-heal and (when Argo manages shop) drift selfHeal.
set -euo pipefail

NS="${NS:-shop}"

need() { command -v "$1" >/dev/null 2>&1 || { echo "missing: $1" >&2; exit 1; }; }
need kubectl

echo "== Pod heal: delete one catalog pod =="
POD="$(kubectl -n "${NS}" get pod -l app.kubernetes.io/name=catalog -o jsonpath='{.items[0].metadata.name}')"
echo "Deleting ${POD}"
kubectl -n "${NS}" delete pod "${POD}" --wait=false
echo "Watching ReplicaSet replace it (Ctrl+C to stop watch early)..."
kubectl -n "${NS}" get pods -l app.kubernetes.io/name=catalog -w &
WATCH_PID=$!
sleep 20
kill "${WATCH_PID}" 2>/dev/null || true
wait "${WATCH_PID}" 2>/dev/null || true
kubectl -n "${NS}" get pods -l app.kubernetes.io/name=catalog

echo
echo "== Desired-state heal: scale catalog away from Git/Helm desired replicas =="
DESIRED="$(kubectl -n "${NS}" get deploy catalog -o jsonpath='{.spec.replicas}')"
echo "Current desired replicas: ${DESIRED}"
kubectl -n "${NS}" scale deploy/catalog --replicas=5
echo "Scaled to 5. If Argo CD Application 'shop' is Synced with selfHeal, it will revert."
echo "Polling for 60s..."
for _ in $(seq 1 12); do
  NOW="$(kubectl -n "${NS}" get deploy catalog -o jsonpath='{.spec.replicas}')"
  echo "  replicas=${NOW}"
  if [[ "${NOW}" == "${DESIRED}" ]]; then
    echo "Reverted to ${DESIRED} (Argo selfHeal or manual helm sync)."
    break
  fi
  sleep 5
done

if kubectl -n argocd get application shop >/dev/null 2>&1; then
  kubectl -n argocd get application shop
else
  echo "No Argo Application 'shop' — restore with:"
  echo "  helm upgrade --install shop deploy/helm/shop -n shop -f deploy/helm/shop/values.yaml -f deploy/helm/shop/values-local.yaml"
  echo "Or set GIT_REPO_URL and re-run bootstrap to enable Argo selfHeal."
fi
