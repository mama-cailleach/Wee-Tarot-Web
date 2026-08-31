import { readFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { describe, expect, it } from "vitest";
import { wrapTextToWidth } from "./textWrap";

const fntPath = path.resolve(
  path.dirname(fileURLToPath(import.meta.url)),
  "../../../assets/fonts/tarotheque-v1-20.fnt",
);

function loadAdvances(): Map<string, number> {
  const widths = new Map<string, number>();
  for (const rawLine of readFileSync(fntPath, "utf8").split(/\r?\n/)) {
    const line = rawLine.trim();
    if (!line || line.startsWith("--") || line.startsWith("tracking=")) {
      continue;
    }
    const match = line.match(/^(.+?)\s+(-?\d+)$/);
    if (!match) {
      continue;
    }
    let character = match[1];
    if (character === "space") {
      character = " ";
    }
    if (character.length === 1) {
      widths.set(character, Number(match[2]));
    }
  }
  return widths;
}

const advances = loadAdvances();

function measure(text: string): number {
  let width = 0;
  for (const character of text) {
    width += advances.get(character) ?? 0;
  }
  return width;
}

describe("wrapTextToWidth", () => {
  it("keeps The Chariot correspondence on three lines", () => {
    const text = "The power of Water surges forward, driven beneath the banner of Cancer.";
    expect(wrapTextToWidth(text, 310, measure).split("\n")).toEqual([
      "The power of Water surges",
      "forward, driven beneath the",
      "banner of Cancer.",
    ]);
  });

  it("does not count a trailing space when deciding if a word fits", () => {
    const withoutSpace = "The power of Water surges";
    const withSpace = `${withoutSpace} `;
    expect(measure(withoutSpace)).toBeLessThanOrEqual(310);
    expect(measure(withSpace)).toBeGreaterThan(310);
    expect(wrapTextToWidth(withoutSpace, 310, measure)).toBe(withoutSpace);
  });

  it("preserves explicit line breaks and wraps each paragraph", () => {
    const text = "Shh... listen closely.\nNo, closer.";
    expect(wrapTextToWidth(text, 310, measure)).toBe(text);
  });
});
