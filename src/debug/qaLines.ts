import { CARD_DATA } from "../game/data/cardData";
import { INTRO_OPTIONS, LAST_LINE_OPTIONS } from "../game/data/oneCardReadingText";
import { KEYWORD_INTRO_OPTIONS } from "../game/data/spreadReadingData";
import { HOW_TO_LINES } from "../game/scenes/HowToScene";
import { INTRO_LINES as MENU_INTRO_LINES } from "../game/scenes/MenuScene";

export type QaLine = {
  group: string;
  source: string;
  text: string;
};

function push(lines: QaLine[], group: string, source: string, text: string): void {
  lines.push({ group, source, text });
}

function keywordSample(keywords: string[], count = 3): string {
  const picked = keywords.slice(0, count);
  if (picked.length === 0) {
    return "";
  }
  return `${picked.join(", ")}.`;
}

/** Every scroll-box string that can appear in the vertical slice. */
export function collectQaLines(): QaLine[] {
  const lines: QaLine[] = [];

  for (const text of MENU_INTRO_LINES) {
    push(lines, "Menu", "intro", text);
  }

  for (const text of HOW_TO_LINES) {
    push(lines, "How To", "dialogue", text);
  }

  for (const text of INTRO_OPTIONS) {
    push(lines, "Reading intro", "Dinah", text);
  }

  for (const [cardName, info] of Object.entries(CARD_DATA)) {
    push(lines, "You pulled", cardName, `You pulled:\n${cardName}`);
    push(lines, "You pulled", `${cardName} inverted`, `You pulled:\n${cardName}\nUpside down`);

    for (const text of info.correspondence ?? []) {
      push(lines, "Correspondence", cardName, text);
    }

    const uprightKeywords = keywordSample(info.upright_keywords);
    if (uprightKeywords) {
      push(lines, "Keywords", `${cardName} upright`, uprightKeywords);
    }
    const reversedKeywords = keywordSample(info.reversed_keywords);
    if (reversedKeywords) {
      push(lines, "Keywords", `${cardName} reversed`, reversedKeywords);
    }

    for (const text of info.upright_fortune) {
      push(lines, "Fortune upright", cardName, text);
    }
    for (const text of info.reversed_fortune) {
      push(lines, "Fortune reversed", cardName, text);
    }
  }

  for (const text of KEYWORD_INTRO_OPTIONS) {
    push(lines, "Keyword intro", "Dinah", text);
  }

  for (const text of LAST_LINE_OPTIONS) {
    push(lines, "Closing", "Dinah", text);
  }

  return lines;
}

export function groupStartIndexes(lines: QaLine[]): number[] {
  const starts: number[] = [];
  let previous = "";
  for (let index = 0; index < lines.length; index += 1) {
    const group = lines[index]?.group ?? "";
    if (group !== previous) {
      starts.push(index);
      previous = group;
    }
  }
  return starts;
}
