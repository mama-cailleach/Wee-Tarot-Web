export const GAME_WIDTH = 400;
export const GAME_HEIGHT = 240;

export const SCENE_FADE_MS = 1000;

export const ASSET_BASE = `${import.meta.env.BASE_URL}assets`;

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
    launchImage2: assetUrl("images", "bg", "launchImage2.png"),
    titleAnim: assetUrl("images", "bg", "titleBGAnim-table-400-391.png"),
    tarotPlayspace: assetUrl("images", "bg", "tarot_playspace.png"),
    darkcloth: assetUrl("images", "bg", "darkcloth.png"),
    iconTriSmol: assetUrl("images", "bg", "icon_tri_smol.png"),
    dinahBg: assetUrl("images", "bg", "dinahBG-table-400-266.png"),
    placementDiamond: assetUrl("images", "decknback", "placementzone_diamond.png"),
    scrollBox: assetUrl("images", "textscroll", "scroll1h.png"),
    shuffle: assetUrl("images", "shuffleAnimation", "1_card_shuffle-table-400-240.png"),
    cardSpinSlide: assetUrl("images", "shuffleAnimation", "card_spin_slide-table-400-240.png"),
    deckLaying: assetUrl("images", "shuffleAnimation", "deck_laying_full_lower-table-400-240.png"),
    explodeDeck: assetUrl("images", "shuffleAnimation", "exploding_deck1-table-400-240.png"),
    scaledCard: assetUrl("images", "shuffleAnimation", "scaled_card-table-400-240.png"),
    explodeFinale: assetUrl("images", "shuffleAnimation", "explode_finale-table-400-240.png"),
    reveal: assetUrl("images", "shuffleAnimation", "reveal-table-236-342.png"),
  },
  audio: {
    cardsSlow: assetUrl("sound", "cards2_slow.wav"),
    cardsFast: assetUrl("sound", "cards2_fast2.wav"),
    crank: assetUrl("sound", "crank5.wav"),
    tuin: assetUrl("sound", "tuin.wav"),
    aBut1: assetUrl("sound", "a_but1.wav"),
    aBut2: assetUrl("sound", "a_but2.wav"),
    aBut3: assetUrl("sound", "a_but3.wav"),
    aBut4: assetUrl("sound", "a_but4.wav"),
    aBut5: assetUrl("sound", "a_but5.wav"),
    aBut6: assetUrl("sound", "a_but6.wav"),
    aBut7: assetUrl("sound", "a_but7.wav"),
    aBut8: assetUrl("sound", "a_but8.wav"),
    aBut9: assetUrl("sound", "a_but9.wav"),
    aBut10: assetUrl("sound", "a_but10.wav"),
    bButton: assetUrl("sound", "b_button.wav"),
    hahahaha: assetUrl("sound", "hahahaha2.wav"),
    bgMusic: assetUrl("sound", "bgMusic3quieter.wav"),
    rain: assetUrl("sound", "rain1quieter.wav"),
    titleStart: assetUrl("sound", "cards_fast.wav"),
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
