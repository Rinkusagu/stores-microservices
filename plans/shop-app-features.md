# Shop app features (frontend + backend)

Status: **planned**

## Goal

Grow the storefront and Python services just enough that a reviewer can browse products, place an order, watch it fulfill, and see failure/degraded paths — without turning the monorepo into a full commerce product. Platform (kind, Helm, OTEL, Argo) stays the headline; the shop becomes a clearer demo workload.

## Current baseline

| Surface | Today |
|---------|--------|
| Storefront | Next.js page: product table + POST order form; HTML confirmation |
| Catalog | Seed list + `GET /products`, `GET /products/{id}` |
| Orders | `POST /orders`, list/get; Redis hash + queue |
| Worker | `BRPOP` → mark `fulfilled` |

Gaps: no order history UI, no status polling, no SKU validation against catalog, no product detail, no stock, no intentional failure path for resilience demos.

## Principles

- Prefer features that show up in Jaeger or heal/scale demos.
- Keep Redis as the store (no Postgres unless a later plan explicitly adds it).
- One job per page/section; storefront stays readable, not a dashboard.
- Ship tests + Compose/Helm env updates with each slice.

---

## Phase A — Order lifecycle (highest demo value)

Make “place order → worker fulfills → UI updates” visible end-to-end.

### Backend

- [ ] **Orders: timestamps + product snapshot** — store `created_at`, `updated_at`, and copy `name` / `price_cents` onto the order hash when created (orders calls catalog `GET /products/{sku}` or storefront passes validated fields; prefer orders→catalog so API stays honest).
- [ ] **Orders: reject unknown SKU** — `400` if catalog returns 404.
- [ ] **Orders: `GET /orders/{id}` already exists** — keep; ensure public JSON includes timestamps + snapshot fields.
- [ ] **Worker: optional `FULFILL_DELAY_MS`** — sleep before fulfill so polling demos are obvious (default `0`).

### Frontend

- [ ] **Orders list page** (`/orders`) — table of recent orders (id, item, qty, status, time); link from home.
- [ ] **Order detail page** (`/orders/[id]`) — status + poll every ~2s while `pending` (stop when `fulfilled` or timeout).
- [ ] **Post-order redirect** — after POST, redirect to `/orders/[id]` instead of static HTML confirmation.
- [ ] **Home link polish** — “View orders” + keep simple table/order CTA.

### Demo payoff

Browser: order → pending → fulfilled. Jaeger: storefront → orders → catalog (validate) → Redis → worker.

---

## Phase B — Catalog depth

- [ ] **Catalog: richer seed** — short `description`, `category` (2–3 categories), keep 4–8 SKUs.
- [ ] **Catalog: `GET /products?category=`** — optional filter.
- [ ] **Catalog: stock field** — `stock` int on each product; `PATCH` or internal decrement helper used by orders.
- [ ] **Orders: stock check** — before enqueue, verify stock; on success decrement (Redis Lua or catalog endpoint with optimistic check). Out-of-stock → `409`.
- [ ] **Frontend: product detail** (`/products/[id]`) — name, price, description, stock, order form.
- [ ] **Frontend: category filter** on home (query param or simple links).

### Demo payoff

Stock race under load; clear 409 path in UI; slightly richer browse without a real CMS.

---

## Phase C — Resilience-facing app behavior

Features that make platform demos more honest at the app layer.

- [ ] **Catalog: `GET /fail` or `?fail=1`** (env-gated) — 500 for chaos / retry demos.
- [ ] **Storefront: bounded retries** on catalog list (1–2 retries, short backoff) + existing timeout; show “degraded / retrying” note when first attempt fails.
- [ ] **Orders: idempotency** — optional `Idempotency-Key` header; Redis key → same order id on replay.
- [ ] **Worker: poison / retry** — on handler error, `RPUSH` to `orders:dead` (or retry count field) instead of silent drop; expose count via orders admin or logs for demos.
- [ ] **Storefront: health/status strip** — small footer: catalog/orders reachability (readyz), not a metrics dashboard.

### Demo payoff

Tied to existing heal scripts: break catalog, show retries + recovery; dead-letter makes worker failures visible.

---

## Phase D — UX / polish (only after A–B)

- [ ] Consistent layout (nav: Shop · Orders), shared styles (keep lean; no card-heavy marketing UI).
- [ ] Empty states: no orders yet; catalog down.
- [ ] Quantity + stock max on forms.
- [ ] Basic a11y: labels on qty, focusable links, sensible headings.

Skip for now (out of scope unless requested): auth/cart/checkout, payments, search engine, admin CMS, Postgres, GraphQL, React Query heavy SPA.

---

## Suggested build order

1. Phase A (order pages + SKU validate + delay) — **do first**
2. Phase B stock + detail — if still thin for screenshots
3. Phase C failure/idempotency — when demoing resilience beyond pod delete
4. Phase D polish last

## Out of scope (platform plans, not this file)

Helm/NetworkPolicy/HPA/Argo/CI changes only as needed to ship the above (new env vars, ports). Larger platform work stays in [resilient-commerce-platform.md](resilient-commerce-platform.md).

## Progress log

- 2026-11-15: Plan drafted from current storefront/catalog/orders/worker baseline.
