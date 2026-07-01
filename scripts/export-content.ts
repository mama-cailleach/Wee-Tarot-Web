import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { lua, lauxlib, lualib, to_luastring } from "fengari";
import { tojs } from "fengari-interop";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, "..");
const contentDir = path.join(root, "content", "data");
const deckDir = path.join(root, "reference", "playdate", "scripts", "decks");
const outDir = path.join(root, "src", "game", "data");

function loadLuaGlobal(filePath: string, globalName: string): unknown {
  const L = lauxlib.luaL_newstate();
  if (!L) {
    throw new Error("Failed to create Lua state");
  }

  lualib.luaL_openlibs(L);

  const status = lauxlib.luaL_dofile(L, to_luastring(filePath));
  if (status !== lua.LUA_OK) {
    const err = lua.lua_tostring(L, -1);
    throw new Error(`Failed to load ${filePath}: ${err ? String(err) : "unknown error"}`);
  }

  lua.lua_getglobal(L, to_luastring(globalName));
  if (lua.lua_isnil(L, -1)) {
    throw new Error(`Global ${globalName} not found in ${filePath}`);
  }

  return tojs(L, -1);
}

function parseStringArray(filePath: string, globalName: string): string[] {
  const value = loadLuaGlobal(filePath, globalName);
  if (!Array.isArray(value)) {
    throw new Error(`${globalName} in ${filePath} is not an array`);
  }
  return value.map((entry) => String(entry).trim());
}

function mergeCardData(): Record<string, unknown> {
  const major = loadLuaGlobal(
    path.join(contentDir, "cardDescriptionsMajor.lua"),
    "CARD_DATA_MAJOR",
  ) as Record<string, unknown>;
  const wands = loadLuaGlobal(
    path.join(contentDir, "cardDescriptionsWands.lua"),
    "CARD_DATA_WANDS",
  ) as Record<string, unknown>;
  const cups = loadLuaGlobal(
    path.join(contentDir, "cardDescriptionsCups.lua"),
    "CARD_DATA_CUPS",
  ) as Record<string, unknown>;
  const swords = loadLuaGlobal(
    path.join(contentDir, "cardDescriptionsSwords.lua"),
    "CARD_DATA_SWORDS",
  ) as Record<string, unknown>;
  const pentacles = loadLuaGlobal(
    path.join(contentDir, "cardDescriptionsPentacles.lua"),
    "CARD_DATA_PENTACLES",
  ) as Record<string, unknown>;

  return { ...major, ...wands, ...cups, ...swords, ...pentacles };
}

function emitFile(filename: string, body: string): void {
  writeFileSync(path.join(outDir, filename), body, "utf8");
}

function serialize(value: unknown, indent = 0): string {
  const pad = "  ".repeat(indent);
  const padInner = "  ".repeat(indent + 1);

  if (value === null || value === undefined) {
    return "null";
  }

  if (typeof value === "string") {
    return JSON.stringify(value);
  }

  if (typeof value === "number" || typeof value === "boolean") {
    return String(value);
  }

  if (Array.isArray(value)) {
    if (value.length === 0) {
      return "[]";
    }
    const items = value.map((item) => `${padInner}${serialize(item, indent + 1)}`);
    return `[\n${items.join(",\n")}\n${pad}]`;
  }

  if (typeof value === "object") {
    const entries = Object.entries(value as Record<string, unknown>);
    if (entries.length === 0) {
      return "{}";
    }
    const items = entries.map(
      ([key, val]) => `${padInner}${JSON.stringify(key)}: ${serialize(val, indent + 1)}`,
    );
    return `{\n${items.join(",\n")}\n${pad}}`;
  }

  return JSON.stringify(value);
}

mkdirSync(outDir, { recursive: true });

const cardData = mergeCardData();

emitFile(
  "types.ts",
  `// AUTO-GENERATED — run npm run export:data

export interface CardInfo {
  correspondence?: string[];
  upright_keywords: string[];
  reversed_keywords: string[];
  upright_fortune: string[];
  reversed_fortune: string[];
}

export type CardDataMap = Record<string, CardInfo>;

export interface ReadingResult {
  cardName: string;
  cardNumber: number;
  cardSuit: number;
  inverted: boolean;
}
`,
);

emitFile(
  "cardData.ts",
  `// AUTO-GENERATED — run npm run export:data

import type { CardDataMap } from "./types";

export const CARD_DATA: CardDataMap = ${serialize(cardData)} as CardDataMap;
`,
);

const deckNames = {
  majorArcana: parseStringArray(path.join(deckDir, "majorArcana.lua"), "majorArcanaDeck"),
  cups: parseStringArray(path.join(deckDir, "cups.lua"), "cupsDeck"),
  wands: parseStringArray(path.join(deckDir, "wands.lua"), "wandsDeck"),
  swords: parseStringArray(path.join(deckDir, "swords.lua"), "swordsDeck"),
  pentacles: parseStringArray(path.join(deckDir, "pentacles.lua"), "pentaclesDeck"),
};

emitFile(
  "deckNames.ts",
  `// AUTO-GENERATED — run npm run export:data

export const SUIT_FOLDERS = ["cups", "wands", "swords", "pentacles", "majorArcana"] as const;

export const DECK_NAMES = ${serialize(deckNames)} as const;
`,
);

console.log(`Exported card data (${Object.keys(cardData).length} cards) and deck names to ${outDir}`);
