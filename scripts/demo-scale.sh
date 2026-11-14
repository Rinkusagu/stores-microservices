#!/usr/bin/env bash
# Generate CPU load so the storefront HPA adds pods.
set -euo pipefail

NS="${NS:-shop}"
HOST="${HOST:-shop.local}"
ROUNDS="${ROUNDS:-40}"

need() { command -v "$1" >/dev/null 2>&1 || { echo "missing: $1" >&2; exit 1; }; }
need kubectl
need curl

echo "== Storefront HPA before load =="
kubectl -n "${NS}" get hpa storefront || true
kubectl -n "${NS}" get pods -l app.kubernetes.io/name=storefront

echo
echo "== Sending CPU burn requests to http://${HOST}/cpu =="
echo "(Ensure /etc/hosts has 127.0.0.1 ${HOST})"
for i in $(seq 1 "${ROUNDS}"); do
  curl -sf "http://${HOST}/cpu?ms=800" >/dev/null &
done
wait || true

echo
echo "== Watching HPA / pods for ~90s =="
kubectl -n "${NS}" get hpa storefront -w &
WATCH_PID=$!
sleep 90
kill "${WATCH_PID}" 2>/dev/null || true
wait "${WATCH_PID}" 2>/dev/null || true

kubectl -n "${NS}" get hpa storefront
kubectl -n "${NS}" get pods -l app.kubernetes.io/name=storefront
echo
echo "Open Jaeger at http://jaeger.local and find a storefront trace after browsing the shop."
