import { burnCpu } from "@/lib/cpu";

export function GET(request: Request): Response {
  const url = new URL(request.url);
  const ms = Number(url.searchParams.get("ms") ?? "200");
  return Response.json(burnCpu(Number.isFinite(ms) ? ms : 200));
}
