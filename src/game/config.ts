export const GAME_WIDTH = 400;
export const GAME_HEIGHT = 240;

export const SCENE_FADE_MS = 1000;

export const ASSET_BASE = "/assets";

export function assetUrl(...parts: string[]): string {
  return `${ASSET_BASE}/${parts.join("/")}`;
}

export interface SpritesheetMeta {
  frameWidth: number;
  frameHeight: number;
}

export function parseSpritesheetMeta(filename: string): SpritesheetMeta | null {
  const match = filename.match(/-table-(\d+)-(\d+)/);
  if (!match) {
    return null;
  }

  return {
    frameWidth: Number(match[1]),
    frameHeight: Number(match[2]),
  };
}

export const SLICE_ASSETS = {
  images: {
    launchImage: assetUrl("images", "bg", "launchImage.png"),
    titleAnim: assetUrl("images", "bg", "titleBGAnim-table-400-391.png"),
    tarotPlayspace: assetUrl("images", "bg", "tarot_playspace.png"),
    darkcloth: assetUrl("images", "bg", "darkcloth.png"),
    dinahBg: assetUrl("images", "bg", "dinahBG-table-400-266.png"),
    placementDiamond: assetUrl("images", "decknback", "placementzone_diamond.png"),
    scrollBox: assetUrl("images", "textscroll", "scroll1h.png"),
    shuffle: assetUrl("images", "shuffleAnimation", "1_card_shuffle-table-400-240.png"),
    cardSpinSlide: assetUrl("images", "shuffleAnimation", "card_spin_slide-table-400-240.png"),
    deckLaying: assetUrl("images", "shuffleAnimation", "deck_laying_full_lower-table-400-240.png"),
    explodeFinale: assetUrl("images", "shuffleAnimation", "explode_finale-table-400-240.png"),
    reveal: assetUrl("images", "shuffleAnimation", "reveal-table-236-342.png"),
    iconTri: assetUrl("images", "bg", "icon_tri_smol.png"),
  },
  audio: {
    cardsSlow: assetUrl("sound", "cards2_slow.wav"),
    cardsFast: assetUrl("sound", "cards2_fast2.wav"),
    crank: assetUrl("sound", "crank5.wav"),
    tuin: assetUrl("sound", "tuin.wav"),
    aBut: assetUrl("sound", "a_but1.wav"),
    bgMusic: assetUrl("sound", "bgMusic3quieter.wav"),
  },
} as const;

export function getCardImageUrl(cardNumber: number, cardSuit: number, zoomed = false): string {
  const folders = ["cups", "wands", "swords", "pentacles", "majorArcana"] as const;
  const folder = folders[cardSuit - 1];
  if (!folder) {
    throw new Error(`Invalid card suit: ${cardSuit}`);
  }

  const suffix = zoomed ? "_zoom" : "";
  return assetUrl("images", folder, `${cardNumber}${suffix}.png`);
}
