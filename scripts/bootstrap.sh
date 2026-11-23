#!/usr/bin/env bash
# Bootstrap a local kind cluster and deploy Resilient Commerce via Helm + Argo CD.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLUSTER_NAME="${CLUSTER_NAME:-resilient-commerce}"
GIT_REPO_URL="${GIT_REPO_URL:-}"

log() { printf '\n==> %s\n' "$*"; }
need() { command -v "$1" >/dev/null 2>&1 || { echo "missing required command: $1" >&2; exit 1; }; }

need docker
need kind
need kubectl
need helm


if [[ "$(uname -s)" != "Linux" ]]; then
  echo "bootstrap.sh targets Linux (kind + host port 80/443). On Windows use WSL2." >&2
fi

cd "$ROOT"

log "Creating kind cluster '${CLUSTER_NAME}' (skip if it already exists)"
if ! kind get clusters 2>/dev/null | grep -qx "${CLUSTER_NAME}"; then
  kind create cluster --config "${ROOT}/deploy/kind/cluster.yaml" --name "${CLUSTER_NAME}"
else
  echo "cluster already exists"
  kind export kubeconfig --name "${CLUSTER_NAME}" >/dev/null
fi
kubectl cluster-info --context "kind-${CLUSTER_NAME}" >/dev/null

IMAGES=(storefront catalog orders worker)
log "Building and loading images into kind"
for svc in "${IMAGES[@]}"; do
  docker build -t "resilient-commerce/${svc}:local" "${ROOT}/apps/${svc}"
  kind load docker-image "resilient-commerce/${svc}:local" --name "${CLUSTER_NAME}"
done

log "Installing ingress-nginx"
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.3/deploy/static/provider/kind/deploy.yaml
kubectl -n ingress-nginx wait --for=condition=available deploy/ingress-nginx-controller --timeout=180s

log "Installing metrics-server (HPA)"
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.7.2/components.yaml
kubectl -n kube-system patch deploy metrics-server --type='json' \
  --patch-file "${ROOT}/deploy/kind/metrics-server-patch.json" || true
kubectl -n kube-system rollout status deploy/metrics-server --timeout=180s || true

log "Creating namespaces"
kubectl create namespace shop --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace shop kubernetes.io/metadata.name=shop --overwrite
kubectl create namespace observability --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace observability kubernetes.io/metadata.name=observability --overwrite

log "Installing Argo CD"
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.13.2/manifests/install.yaml
kubectl -n argocd wait --for=condition=available deploy/argocd-server --timeout=300s

log "Applying observability (Jaeger + OTel Collector)"
kubectl apply -k "${ROOT}/deploy/observability"
kubectl -n observability rollout status deploy/jaeger --timeout=180s || true
kubectl -n observability rollout status deploy/otel-collector --timeout=180s || true

log "Installing shop Helm release (local images, imagePullPolicy Never)"
helm upgrade --install shop "${ROOT}/deploy/helm/shop" \
  --namespace shop \
  --create-namespace \
  -f "${ROOT}/deploy/helm/shop/values.yaml" \
  -f "${ROOT}/deploy/helm/shop/values-local.yaml" \
  --wait --timeout 5m

apply_gitops() {
  local url="$1"
  local tmp
  tmp="$(mktemp -d)"
  sed "s|REPLACEME_GIT_REPO_URL|${url}|g" "${ROOT}/deploy/gitops/apps/shop.yaml" >"${tmp}/shop.yaml"
  sed "s|REPLACEME_GIT_REPO_URL|${url}|g" "${ROOT}/deploy/gitops/apps/observability.yaml" >"${tmp}/observability.yaml"
  sed "s|REPLACEME_GIT_REPO_URL|${url}|g" "${ROOT}/deploy/gitops/root-app.yaml" >"${tmp}/root-app.yaml"
  kubectl apply -f "${tmp}/observability.yaml"
  kubectl apply -f "${tmp}/shop.yaml"
  kubectl apply -f "${tmp}/root-app.yaml"
  rm -rf "${tmp}"
}

if [[ -n "${GIT_REPO_URL}" ]]; then
  log "Registering GitOps apps for ${GIT_REPO_URL}"
  apply_gitops "${GIT_REPO_URL}"
  echo "Argo CD will sync shop + observability from git (automated selfHeal)."
else
  log "GIT_REPO_URL unset — shop is live via Helm; Argo apps not registered"
  echo "Set GIT_REPO_URL to your GitHub clone URL and re-run bootstrap (or apply deploy/gitops) for Argo self-heal."
fi

log "Waiting for shop workloads"
kubectl -n shop wait --for=condition=available deploy --all --timeout=180s || true

cat <<EOF

Bootstrap complete.

  Shop UI:    http://shop.local   (add '127.0.0.1 shop.local' to /etc/hosts)
  Jaeger UI:  http://jaeger.local (add '127.0.0.1 jaeger.local' to /etc/hosts)

  Demos:  ./scripts/demo-heal.sh
          ./scripts/demo-scale.sh
  Tear down: ./scripts/teardown.sh

EOF
