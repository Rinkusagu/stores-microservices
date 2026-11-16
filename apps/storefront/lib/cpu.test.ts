import { describe, expect, it } from "vitest";
import { burnCpu } from "./cpu";

describe("burnCpu", () => {
  it("returns iterations above zero", () => {
    const result = burnCpu(10);
    expect(result.iterations).toBeGreaterThan(0);
    expect(result.burned_ms).toBe(10);
  });
});
