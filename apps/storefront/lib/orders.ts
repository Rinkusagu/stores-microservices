import { ordersUrl } from "./config";

export type Order = {
  id: string;
  sku: string;
  qty: number;
  status: string;
};

export async function placeOrder(sku: string, qty: number): Promise<Order> {
  const response = await fetch(`${ordersUrl()}/orders`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ sku, qty }),
    cache: "no-store",
    signal: AbortSignal.timeout(3000),
  });
  if (!response.ok) {
    throw new Error(`orders HTTP ${response.status}`);
  }
  return (await response.json()) as Order;
}
