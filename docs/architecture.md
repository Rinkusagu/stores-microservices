# Architecture

## Request path

1. Browser hits Ingress (`shop.local`) → **storefront** (Next.js).
2. Storefront calls **catalog** for the product list and **orders** to place an order.
3. Orders writes a Redis hash (`order:<id>`) and `LPUSH`es a job onto `orders:queue`.
4. **Worker** `BRPOP`s the queue, marks the order `fulfilled`, and continues the OTEL trace via `traceparent`.

Traces leave each process over OTLP/gRPC to the **OpenTelemetry Collector**, which exports to **Jaeger**. There is no Prometheus scrape path and no Grafana in this project.

## Why Redis instead of a database

The shop is a demo workload, not a commerce product. Redis gives a durable-enough handoff between the HTTP API and the worker without running a multi-replica database, migrations, or backups. Order state is a hash plus a queue — enough to show async work and a single distributed trace.

## Healing layers

| Layer | Mechanism | What you see |
|-------|-----------|--------------|
| Container | Liveness + readiness probes | Bad process restarted |
| Pod | `replicaCount >= 2`, PDB, ReplicaSet | Deleted pod replaced |
| Workload | HPA on CPU (storefront, catalog) via metrics-server | Extra pods under load |
| Desired state | Argo CD `selfHeal: true` | Manual `kubectl scale` reverted |
| Nodes (AWS only) | Managed node group + Cluster Autoscaler IRSA | Documented in `docs/aws.md`; kind cannot show node scale-up |

## Network

The shop namespace starts with default-deny NetworkPolicies. Storefront may reach catalog, orders, and the collector. Orders and worker may reach Redis and the collector. Ingress-nginx may reach storefront (and Jaeger UI). Nothing else is allowed east-west.
