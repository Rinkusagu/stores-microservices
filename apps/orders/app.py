import json
import os
import uuid

import redis
from fastapi import FastAPI, HTTPException
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.propagate import inject
from pydantic import BaseModel, Field

from telemetry import init_tracing

init_tracing("orders")

QUEUE_KEY = "orders:queue"
IDS_KEY = "orders:ids"

app = FastAPI(title="orders")
FastAPIInstrumentor.instrument_app(app)


class OrderIn(BaseModel):
    sku: str = Field(min_length=1)
    qty: int = Field(ge=1, le=20)


def order_key(order_id: str) -> str:
    return f"order:{order_id}"


def get_redis() -> redis.Redis:
    client = getattr(app.state, "redis", None)
    if client is None:
        client = redis.Redis.from_url(os.environ["REDIS_URL"], decode_responses=True)
        app.state.redis = client
    return client


def create_order(client: redis.Redis, sku: str, qty: int) -> dict:
    order_id = str(uuid.uuid4())
    record = {"id": order_id, "sku": sku, "qty": str(qty), "status": "pending"}
    client.hset(order_key(order_id), mapping=record)
    client.sadd(IDS_KEY, order_id)
    carrier: dict[str, str] = {}
    inject(carrier)
    payload = {"order_id": order_id, "traceparent": carrier.get("traceparent", "")}
    client.lpush(QUEUE_KEY, json.dumps(payload))
    return {"id": order_id, "sku": sku, "qty": qty, "status": "pending"}


def list_orders(client: redis.Redis) -> list[dict]:
    orders = []
    for order_id in sorted(client.smembers(IDS_KEY)):
        data = client.hgetall(order_key(order_id))
        if data:
            orders.append(_public(data))
    return orders


def fetch_order(client: redis.Redis, order_id: str) -> dict | None:
    data = client.hgetall(order_key(order_id))
    if not data:
        return None
    return _public(data)


def _public(data: dict) -> dict:
    return {
        "id": data["id"],
        "sku": data["sku"],
        "qty": int(data["qty"]),
        "status": data["status"],
    }


@app.get("/healthz")
def healthz() -> dict:
    return {"status": "ok"}


@app.get("/readyz")
def readyz() -> dict:
    try:
        get_redis().ping()
    except redis.RedisError as exc:
        raise HTTPException(status_code=503, detail="redis unavailable") from exc
    return {"status": "ready"}


@app.post("/orders", status_code=201)
def post_order(body: OrderIn) -> dict:
    return create_order(get_redis(), body.sku, body.qty)


@app.get("/orders")
def get_orders() -> dict:
    return {"orders": list_orders(get_redis())}


@app.get("/orders/{order_id}")
def get_order(order_id: str) -> dict:
    order = fetch_order(get_redis(), order_id)
    if order is None:
        raise HTTPException(status_code=404, detail="order not found")
    return order
