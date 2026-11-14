import os
import time
from html import escape

import httpx
from fastapi import FastAPI, Form
from fastapi.responses import HTMLResponse
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.instrumentation.httpx import HTTPXClientInstrumentor

from telemetry import init_tracing

init_tracing("storefront")
HTTPXClientInstrumentor().instrument()

app = FastAPI(title="storefront")
FastAPIInstrumentor.instrument_app(app)

CATALOG_URL = os.getenv("CATALOG_URL", "http://catalog:8080")
ORDERS_URL = os.getenv("ORDERS_URL", "http://orders:8080")


def page(body: str) -> HTMLResponse:
    html = f"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Resilient Commerce</title>
  <style>
    body {{ font-family: Georgia, serif; margin: 2rem auto; max-width: 42rem; color: #1c1917; }}
    h1 {{ font-weight: 500; }}
    table {{ border-collapse: collapse; width: 100%; }}
    td, th {{ text-align: left; padding: 0.4rem 0.2rem; border-bottom: 1px solid #e7e5e4; }}
    button {{ font: inherit; padding: 0.2rem 0.6rem; }}
    .note {{ color: #44403c; }}
  </style>
</head>
<body>
  <h1>Resilient Commerce</h1>
  {body}
</body>
</html>"""
    return HTMLResponse(html)


@app.get("/healthz")
def healthz() -> dict:
    return {"status": "ok"}


@app.get("/readyz")
def readyz() -> dict:
    return {"status": "ready"}


@app.get("/cpu")
def cpu(ms: int = 200) -> dict:
    """Burn CPU so the HorizontalPodAutoscaler has something to scale on."""
    duration = max(1, min(ms, 2000)) / 1000
    deadline = time.perf_counter() + duration
    n = 0
    while time.perf_counter() < deadline:
        n += 1
    return {"burned_ms": duration * 1000, "iterations": n}


@app.get("/", response_class=HTMLResponse)
def home() -> HTMLResponse:
    try:
        response = httpx.get(f"{CATALOG_URL}/products", timeout=3.0)
        response.raise_for_status()
        products = response.json()["products"]
    except httpx.HTTPError as exc:
        return page(f"<p class='note'>Catalog is unavailable: {escape(str(exc))}</p>")

    rows = []
    for product in products:
        price = product["price_cents"] / 100
        rows.append(
            "<tr>"
            f"<td>{escape(product['name'])}</td>"
            f"<td>${price:.2f}</td>"
            "<td><form method='post' action='/orders'>"
            f"<input type='hidden' name='sku' value='{escape(product['id'])}'>"
            "<input type='number' name='qty' value='1' min='1' max='20'>"
            "<button type='submit'>Order</button>"
            "</form></td></tr>"
        )
    table = (
        "<table><tr><th>Item</th><th>Price</th><th></th></tr>"
        + "".join(rows)
        + "</table>"
    )
    return page(table)


@app.post("/orders", response_class=HTMLResponse)
def place_order(sku: str = Form(...), qty: int = Form(...)) -> HTMLResponse:
    try:
        response = httpx.post(
            f"{ORDERS_URL}/orders",
            json={"sku": sku, "qty": qty},
            timeout=3.0,
        )
        response.raise_for_status()
        order = response.json()
    except httpx.HTTPError as exc:
        return page(f"<p class='note'>Could not place the order: {escape(str(exc))}</p>")

    return page(
        "<p>Order accepted.</p>"
        f"<p>id <code>{escape(order['id'])}</code> · status {escape(order['status'])}</p>"
        "<p><a href='/'>Back to the shop</a></p>"
    )
