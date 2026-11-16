import { describe, expect, it } from "vitest";
import { escapeHtml, page } from "./html";

describe("html helpers", () => {
  it("escapes markup", () => {
    expect(escapeHtml("<b>&\"'")).toContain("&lt;");
    expect(escapeHtml("<b>&\"'")).toContain("&amp;");
    expect(escapeHtml('"quoted"')).toContain("&quot;");
  });

  it("wraps body in shop page shell", () => {
    const html = page("<p>hello</p>");
    expect(html).toContain("Resilient Commerce");
    expect(html).toContain("<p>hello</p>");
  });
});
