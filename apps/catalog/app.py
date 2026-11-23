from fastapi import FastAPI, HTTPException
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor

from telemetry import init_tracing

init_tracing("catalog")

PRODUCTS = [
    {"id": "sku-100", "name": "Graph Notebook A5", "price_cents": 1800},
    {"id": "sku-200", "name": "Mechanical Pencil Set", "price_cents": 2400},
    {"id": "sku-300", "name": "Highlighter Pack (6)", "price_cents": 3200},
    {"id": "sku-400", "name": "Desk Flashcards (200)", "price_cents": 1400},
]

app = FastAPI(title="catalog")
FastAPIInstrumentor.instrument_app(app)


def _product(product_id: str) -> dict | None:
    return next((item for item in PRODUCTS if item["id"] == product_id), None)


@app.get("/healthz")
def healthz() -> dict:
    return {"status": "ok"}


@app.get("/readyz")
def readyz() -> dict:
    return {"status": "ready"}


@app.get("/products")
def list_products() -> dict:
    return {"products": PRODUCTS}


@app.get("/products/{product_id}")
def get_product(product_id: str) -> dict:
    product = _product(product_id)
    if product is None:
        raise HTTPException(status_code=404, detail="product not found")
    return product
