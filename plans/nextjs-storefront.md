# Next.js storefront rewrite

Status: **done**

## Goal

Replace the Python FastAPI storefront with Next.js 15 (App Router) while keeping routes, env vars, Compose, Helm, and CI contracts.

## Checklist

- [x] Scaffold Next.js app under `apps/storefront` (routes, lib, instrumentation)
- [x] Remove Python storefront sources and pytest
- [x] Node Dockerfile + Compose healthcheck
- [x] Helm memory + `.next/cache` emptyDir
- [x] CI storefront job; update Makefile/README/PLAN

## Progress log

- 2026-11-15: Storefront rewritten to Next.js; Docker/Compose/Helm/CI updated.
