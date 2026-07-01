import { describe, expect, it } from "vitest";
import { buildLines } from "./oneCardReadingText";

describe("oneCardReadingText", () => {
  it("builds reading lines for The Fool", () => {
    const { lines, themes } = buildLines("The Fool", false);

    expect(lines.length).toBeGreaterThan(4);
    expect(lines.some((line) => line.includes("The Fool"))).toBe(true);
    expect(themes.length).toBeGreaterThan(0);
  });

  it("marks reversed pulls", () => {
    const { lines } = buildLines("The Magician", true);
    expect(lines.some((line) => line.includes("Upside down"))).toBe(true);
  });
});
