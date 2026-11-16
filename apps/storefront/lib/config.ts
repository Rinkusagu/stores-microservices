export function catalogUrl(): string {
  return process.env.CATALOG_URL?.trim() || "http://catalog:8080";
}

export function ordersUrl(): string {
  return process.env.ORDERS_URL?.trim() || "http://orders:8080";
}
