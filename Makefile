.PHONY: bootstrap teardown demo-heal demo-scale lint test storefront-test helm-lint up down logs

bootstrap:
	./scripts/bootstrap.sh

teardown:
	./scripts/teardown.sh

demo-heal:
	./scripts/demo-heal.sh

demo-scale:
	./scripts/demo-scale.sh

lint:
	ruff check apps

test:
	pytest -q apps/catalog/tests apps/orders/tests apps/worker/tests

storefront-test:
	cd apps/storefront && npm test

helm-lint:
	helm lint deploy/helm/shop

up:
	docker compose up --build -d

down:
	docker compose down -v

logs:
	docker compose logs -f
