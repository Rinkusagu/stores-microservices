from fastapi.testclient import TestClient

import app as storefront


def test_health() -> None:
    client = TestClient(storefront.app)
    assert client.get("/healthz").json() == {"status": "ok"}
    assert client.get("/readyz").status_code == 200


def test_home_lists_products(monkeypatch) -> None:
    class Response:
        def raise_for_status(self) -> None:
            return None

        def json(self) -> dict:
            return {"products": [{"id": "sku-100", "name": "Trail Bottle", "price_cents": 1800}]}

    monkeypatch.setattr(storefront.httpx, "get", lambda *args, **kwargs: Response())
    client = TestClient(storefront.app)
    response = client.get("/")
    assert response.status_code == 200
    assert "Trail Bottle" in response.text


def test_place_order(monkeypatch) -> None:
    class Response:
        def raise_for_status(self) -> None:
            return None

        def json(self) -> dict:
            return {"id": "abc", "sku": "sku-100", "qty": 1, "status": "pending"}

    monkeypatch.setattr(storefront.httpx, "post", lambda *args, **kwargs: Response())
    client = TestClient(storefront.app)
    response = client.post("/orders", data={"sku": "sku-100", "qty": "1"})
    assert response.status_code == 200
    assert "abc" in response.text


def test_cpu_burn() -> None:
    client = TestClient(storefront.app)
    response = client.get("/cpu", params={"ms": 10})
    assert response.status_code == 200
    assert response.json()["iterations"] > 0
