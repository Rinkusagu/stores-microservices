import { afterEach, describe, expect, it, vi } from "vitest";
import { listProducts } from "./catalog";

afterEach(() => {
  vi.unstubAllGlobals();
  vi.restoreAllMocks();
});

describe("listProducts", () => {
  it("returns products from catalog", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn(async () =>
        Response.json({
          products: [
            { id: "sku-100", name: "Trail Bottle", price_cents: 1800 },
          ],
        }),
      ),
    );
    const products = await listProducts();
    expect(products[0]?.name).toBe("Trail Bottle");
  });
});
