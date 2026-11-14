#!/usr/bin/env bash
# Delete the local kind cluster.
set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-resilient-commerce}"

if ! command -v kind >/dev/null 2>&1; then
  echo "kind not found" >&2
  exit 1
fi

if kind get clusters 2>/dev/null | grep -qx "${CLUSTER_NAME}"; then
  echo "Deleting kind cluster '${CLUSTER_NAME}'..."
  kind delete cluster --name "${CLUSTER_NAME}"
  echo "Done."
else
  echo "Cluster '${CLUSTER_NAME}' not found."
fi
