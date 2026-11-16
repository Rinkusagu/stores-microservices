import { afterEach, describe, expect, it, vi } from "vitest";
import { placeOrder } from "./orders";

afterEach(() => {
  vi.unstubAllGlobals();
  vi.restoreAllMocks();
});

describe("placeOrder", () => {
  it("posts order and returns body", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn(async () =>
        Response.json({
          id: "abc",
          sku: "sku-100",
          qty: 1,
          status: "pending",
        }),
      ),
    );
    const order = await placeOrder("sku-100", 1);
    expect(order.id).toBe("abc");
    expect(order.status).toBe("pending");
  });
});
