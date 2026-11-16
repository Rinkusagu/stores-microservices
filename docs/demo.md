# Five-minute demo

Prerequisites: Linux (or WSL2), Docker, kind, kubectl, helm. About 8 GB RAM free for the kind cluster.

## Start

```bash
./scripts/bootstrap.sh
# or: make bootstrap
```

Add hosts entries:

```text
127.0.0.1 shop.local
127.0.0.1 jaeger.local
```

Open http://shop.local — list products and place an order.

## 1. Pod heal

```bash
./scripts/demo-heal.sh
```

Good: a catalog pod disappears and a new one becomes Ready within seconds (ReplicaSet + probes).

## 2. Argo self-heal (optional)

Set `GIT_REPO_URL` to this repo’s GitHub URL and re-run bootstrap so Argo Applications register. Then `demo-heal.sh` scales catalog to 5 and waits for Argo to revert to the Git desired count.

Without GitOps, restore with:

```bash
helm upgrade --install shop deploy/helm/shop -n shop \
  -f deploy/helm/shop/values.yaml \
  -f deploy/helm/shop/values-local.yaml
```

## 3. HPA scale

```bash
./scripts/demo-scale.sh
```

Good: storefront HPA `TARGETS` CPU rises and `REPLICAS` climb above 2 (may take a minute).

## 4. One trace in Jaeger

Browse the shop (list + order), then open http://jaeger.local. Find a **storefront** trace that includes catalog and orders spans; the worker span appears when the queue job is processed.

## Tear down

```bash
./scripts/teardown.sh
```
