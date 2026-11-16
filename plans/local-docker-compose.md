# Local Docker Compose smoke stack

Status: **done**

## Goal

Run Redis + all shop microservices with Docker Compose and a `.env` file so orders (and the full path) can be tested without kind/WSL.

## Checklist

- [x] Add `docker-compose.yml` (redis, catalog, orders, worker, storefront)
- [x] Add `.env` + `.env.example` (ports + `REDIS_URL` + service URLs)
- [x] Allow `.env.example` in `.gitignore`
- [x] Add Makefile `up` / `down` / `logs` targets

## Progress log

- 2026-11-15: Compose stack and env files added for local PowerShell/Docker Desktop testing.
