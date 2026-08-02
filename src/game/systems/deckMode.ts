import type Phaser from "phaser";

export type DeckMode = "full" | "major";

export const DECK_MODE_KEY = "deckMode";

const LABELS: Record<DeckMode, string> = {
  full: "Full Deck",
  major: "Major Arcana",
};

function isDeckMode(value: unknown): value is DeckMode {
  return value === "full" || value === "major";
}

export function getDeckMode(registry: Phaser.Data.DataManager): DeckMode {
  const value = registry.get(DECK_MODE_KEY);
  return isDeckMode(value) ? value : "full";
}

export function setDeckMode(registry: Phaser.Data.DataManager, mode: DeckMode): void {
  registry.set(DECK_MODE_KEY, mode);
}

export function deckModeLabel(mode: DeckMode): string {
  return LABELS[mode];
}

export function toggleDeckMode(mode: DeckMode): DeckMode {
  return mode === "full" ? "major" : "full";
}
