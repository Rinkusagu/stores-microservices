import type { CSSProperties } from "react";
import { listProducts } from "@/lib/catalog";

export const dynamic = "force-dynamic";

const cell: CSSProperties = {
  textAlign: "left",
  padding: "0.4rem 0.2rem",
  borderBottom: "1px solid #e7e5e4",
};

export default async function HomePage() {
  let products;
  let error: string | null = null;
  try {
    products = await listProducts();
  } catch (err) {
    error = err instanceof Error ? err.message : String(err);
  }

  return (
    <>
      <h1 style={{ fontWeight: 500 }}>Resilient Commerce</h1>
      {error ? (
        <p style={{ color: "#44403c" }}>Catalog is unavailable: {error}</p>
      ) : (
        <table style={{ borderCollapse: "collapse", width: "100%" }}>
          <thead>
            <tr>
              <th style={cell}>Item</th>
              <th style={cell}>Price</th>
              <th style={cell} />
            </tr>
          </thead>
          <tbody>
            {products!.map((product) => (
              <tr key={product.id}>
                <td style={cell}>{product.name}</td>
                <td style={cell}>${(product.price_cents / 100).toFixed(2)}</td>
                <td style={cell}>
                  <form method="post" action="/orders">
                    <input type="hidden" name="sku" value={product.id} />
                    <input
                      type="number"
                      name="qty"
                      defaultValue={1}
                      min={1}
                      max={20}
                    />
                    <button
                      type="submit"
                      style={{ font: "inherit", padding: "0.2rem 0.6rem" }}
                    >
                      Order
                    </button>
                  </form>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </>
  );
}
