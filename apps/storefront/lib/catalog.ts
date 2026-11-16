import { catalogUrl } from "./config";

export type Product = {
  id: string;
  name: string;
  price_cents: number;
};

export async function listProducts(): Promise<Product[]> {
  const response = await fetch(`${catalogUrl()}/products`, {
    cache: "no-store",
    signal: AbortSignal.timeout(3000),
  });
  if (!response.ok) {
    throw new Error(`catalog HTTP ${response.status}`);
  }
  const body = (await response.json()) as { products: Product[] };
  return body.products;
}
