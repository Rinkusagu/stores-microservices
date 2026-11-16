import { describe, expect, it } from "vitest";
import { GET as healthz } from "./route";
import { GET as readyz } from "../readyz/route";
import { GET as cpu } from "../cpu/route";

describe("probe routes", () => {
  it("healthz and readyz return ok json", async () => {
    expect(await healthz().json()).toEqual({ status: "ok" });
    expect(await readyz().json()).toEqual({ status: "ready" });
  });

  it("cpu burns iterations", async () => {
    const response = cpu(new Request("http://localhost/cpu?ms=10"));
    const body = await response.json();
    expect(body.iterations).toBeGreaterThan(0);
  });
});
