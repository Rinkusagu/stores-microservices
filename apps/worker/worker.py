import json
import os
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from threading import Thread

import redis
from opentelemetry import trace
from opentelemetry.propagate import extract

from telemetry import init_tracing

QUEUE_KEY = "orders:queue"
init_tracing("worker")
TRACER = trace.get_tracer("worker")
READY = False


def order_key(order_id: str) -> str:
    return f"order:{order_id}"


def fulfill(client: redis.Redis, payload: dict) -> str:
    order_id = payload["order_id"]
    carrier = {}
    if payload.get("traceparent"):
        carrier["traceparent"] = payload["traceparent"]
    context = extract(carrier)
    with TRACER.start_as_current_span("fulfill_order", context=context):
        client.hset(order_key(order_id), "status", "fulfilled")
    return order_id


def handle_message(client: redis.Redis, raw: str) -> str:
    payload = json.loads(raw)
    return fulfill(client, payload)


class HealthHandler(BaseHTTPRequestHandler):
    def do_GET(self) -> None:
        if self.path == "/healthz":
            body = b'{"status":"ok"}'
            status = 200
        elif self.path == "/readyz":
            if READY:
                body = b'{"status":"ready"}'
                status = 200
            else:
                body = b'{"status":"starting"}'
                status = 503
        else:
            body = b'{"detail":"not found"}'
            status = 404
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, fmt: str, *args) -> None:
        return


def serve_health(port: int) -> None:
    server = ThreadingHTTPServer(("0.0.0.0", port), HealthHandler)
    server.serve_forever()


def main() -> None:
    global READY
    port = int(os.getenv("PORT", "8080"))
    Thread(target=serve_health, args=(port,), daemon=True).start()
    client = redis.Redis.from_url(os.environ["REDIS_URL"], decode_responses=True)
    while True:
        try:
            client.ping()
            break
        except redis.RedisError:
            time.sleep(2)
    READY = True
    while True:
        item = client.brpop(QUEUE_KEY, timeout=5)
        if item is None:
            continue
        _, raw = item
        handle_message(client, raw)


if __name__ == "__main__":
    main()
