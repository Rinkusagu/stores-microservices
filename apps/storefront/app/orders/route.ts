import { escapeHtml, page } from "@/lib/html";
import { placeOrder } from "@/lib/orders";

export async function POST(request: Request): Promise<Response> {
  const form = await request.formData();
  const sku = String(form.get("sku") ?? "");
  const qty = Number(form.get("qty") ?? 0);

  try {
    const order = await placeOrder(sku, qty);
    const body = page(
      `<p>Order accepted.</p>` +
        `<p>id <code>${escapeHtml(order.id)}</code> · status ${escapeHtml(order.status)}</p>` +
        `<p><a href="/">Back to the shop</a></p>`,
    );
    return new Response(body, {
      status: 200,
      headers: { "Content-Type": "text/html; charset=utf-8" },
    });
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    const body = page(
      `<p class="note">Could not place the order: ${escapeHtml(message)}</p>`,
    );
    return new Response(body, {
      status: 200,
      headers: { "Content-Type": "text/html; charset=utf-8" },
    });
  }
}
