import { CARD_DATA } from "./cardData";
import type { CardInfo } from "./types";

const FALLBACK_KEYWORDS = ["mystery", "uncertain path", "hidden lesson"];

const KEYWORD_INTRO_OPTIONS = [
  "The spirits whisper... ",
  "The card's pulse summons forth: ",
  "The oracles of old murmur of: ",
  "From the sands of time, this card reveals: ",
  "This card hums with forgotten truths: ",
  "From the woven threads of fate, we find: ",
  "Here lies the essence unveiled: ",
  "Let these currents stir the soul: ",
];

function shuffledCopy<T>(items: T[]): T[] {
  const copy = [...items];
  for (let index = copy.length; index > 1; index -= 1) {
    const swapIndex = Math.floor(Math.random() * index);
    [copy[index - 1], copy[swapIndex]] = [copy[swapIndex], copy[index - 1]];
  }
  return copy;
}

function pickRandomLine(lines: string[] | undefined): string | undefined {
  if (!lines || lines.length === 0) {
    return undefined;
  }
  return lines[Math.floor(Math.random() * lines.length)];
}

export function normalizeSpreadKey(spreadKey: string): string {
  return spreadKey.toLowerCase().replace(/-/g, "_");
}

export function pickKeywords(
  cardName: string,
  inverted: boolean,
  keywordCount = 3,
): string[] {
  const cardInfo: CardInfo | undefined = CARD_DATA[cardName];
  if (!cardInfo) {
    return FALLBACK_KEYWORDS;
  }

  let sourceKeywords = cardInfo.upright_keywords ?? [];
  if (inverted && cardInfo.reversed_keywords.length > 0) {
    sourceKeywords = cardInfo.reversed_keywords;
  }

  if (sourceKeywords.length === 0) {
    return FALLBACK_KEYWORDS;
  }

  if (sourceKeywords.length <= keywordCount) {
    return sourceKeywords;
  }

  return shuffledCopy(sourceKeywords).slice(0, keywordCount);
}

export function pickKeywordIntroLine(): string {
  return KEYWORD_INTRO_OPTIONS[Math.floor(Math.random() * KEYWORD_INTRO_OPTIONS.length)];
}

export { pickRandomLine };
