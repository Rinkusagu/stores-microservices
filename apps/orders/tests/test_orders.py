import fakeredis
from fastapi.testclient import TestClient

from app import app

client = TestClient(app)


def setup_function() -> None:
    app.state.redis = fakeredis.FakeRedis(decode_responses=True)


def test_health_and_ready() -> None:
    assert client.get("/healthz").json() == {"status": "ok"}
    assert client.get("/readyz").json() == {"status": "ready"}


def test_create_and_fetch_order() -> None:
    created = client.post("/orders", json={"sku": "sku-100", "qty": 2})
    assert created.status_code == 201
    body = created.json()
    assert body["status"] == "pending"
    assert body["sku"] == "sku-100"

    fetched = client.get(f"/orders/{body['id']}")
    assert fetched.status_code == 200
    assert fetched.json()["qty"] == 2

    listing = client.get("/orders")
    assert listing.json()["orders"][0]["id"] == body["id"]

    queued = app.state.redis.lpop("orders:queue")
    assert body["id"] in queued


def test_missing_order() -> None:
    assert client.get("/orders/missing").status_code == 404
