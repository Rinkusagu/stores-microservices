from fastapi.testclient import TestClient

from app import app

client = TestClient(app)


def test_health() -> None:
    assert client.get("/healthz").json() == {"status": "ok"}
    assert client.get("/readyz").status_code == 200


def test_list_products() -> None:
    response = client.get("/products")
    assert response.status_code == 200
    products = response.json()["products"]
    assert len(products) == 4
    assert products[0]["id"] == "sku-100"


def test_get_product_missing() -> None:
    response = client.get("/products/missing")
    assert response.status_code == 404
