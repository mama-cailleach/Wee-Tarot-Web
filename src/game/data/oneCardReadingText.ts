import { CARD_DATA } from "./cardData";
import { pickKeywordIntroLine, pickKeywords } from "./spreadReadingData";

export const INTRO_OPTIONS = [
  "Hmmmm... Hmmmm...\n(squints at the card)\nVery interesting…",
  "(looks at you with a raised eyebrow)",
  "Shh... listen closely.\nNo, closer.",
  "Patience. The universe loves a dramatic pause.",
  "We may glimpse the dawn… or another dark night of the soul. Let's see.",
  "(sighs) Well, every card is a mirror. Know thyself…\nif you dare to look.",
  "Let me peer through the veil… it's a bit wrinkled today.",
  "Ah, this one… I remember its dance with fate.",
];

export const LAST_LINE_OPTIONS = [
  "You can press *Leave* or *Cloth* now darling, but I will not tell you what to do.",
  "A final peek with *Cloth*, or *Leave* and let fate close the door.",
  "Last look at the *Cloth*? If not *Leave* knows the way. The card will not follow.",
  "If your heart clings, *Cloth*. If it dares, *Leave*. The card forgets you soon.",
  "*Cloth* for one last look. *Leave* to move on. The past doesn't wait, dearie.",
  "One last glance? *Cloth*. Ready to let go? *Leave*. The veil doesn't open twice.",
];

export function buildLines(
  cardName: string,
  isInverted: boolean,
): { lines: string[]; themes: string[] } {
  const cardInfo = CARD_DATA[cardName];
  if (!cardInfo) {
    console.warn(`No data found for card: ${cardName}`);
  }

  const info = cardInfo ?? CARD_DATA["The Fool"];
  const lines: string[] = [];

  lines.push(INTRO_OPTIONS[Math.floor(Math.random() * INTRO_OPTIONS.length)]);

  const intro = `You pulled:\n${cardName}${isInverted ? "\nUpside down" : ""}`;
  lines.push(intro);

  if (info.correspondence && info.correspondence.length > 0) {
    lines.push(...info.correspondence);
  }

  const themes = pickKeywords(cardName, isInverted, 3);
  lines.push(pickKeywordIntroLine());

  if (themes.length > 0) {
    lines.push(`${themes.join(", ")}.`);
  }

  const fortuneLines = isInverted ? info.reversed_fortune : info.upright_fortune;
  lines.push(fortuneLines[Math.floor(Math.random() * fortuneLines.length)]);

  lines.push(LAST_LINE_OPTIONS[Math.floor(Math.random() * LAST_LINE_OPTIONS.length)]);

  return { lines, themes };
}
