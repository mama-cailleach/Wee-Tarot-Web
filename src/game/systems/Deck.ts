import { DECK_NAMES } from "../data/deckNames";

const SUIT_NAME_TO_INDEX: Record<string, number> = {
  cups: 1,
  wands: 2,
  swords: 3,
  pentacles: 4,
  major: 5,
};

export interface DrawResult {
  cardName: string;
  cardNumber: number;
  cardSuit: number;
}

export type DeckFilter =
  | "full"
  | "major"
  | "minor"
  | "cups"
  | "wands"
  | "swords"
  | "pentacles"
  | "alternate";

export class Deck {
  private cupsDeck = [...DECK_NAMES.cups];
  private wandsDeck = [...DECK_NAMES.wands];
  private swordsDeck = [...DECK_NAMES.swords];
  private pentaclesDeck = [...DECK_NAMES.pentacles];
  private majorArcanaDeck = [...DECK_NAMES.majorArcana];

  private allDecks = [
    this.cupsDeck,
    this.wandsDeck,
    this.swordsDeck,
    this.pentaclesDeck,
    this.majorArcanaDeck,
  ];

  private alternateDeckMode = false;
  private alternateAvailableSuits: number[] = [];
  private alternateUsedCount = 0;

  private drawFromDeck(deck: string[], suitIndex: number): DrawResult | null {
    if (deck.length === 0) {
      return null;
    }

    const column = Math.floor(Math.random() * deck.length);
    return {
      cardName: deck[column],
      cardNumber: column + 1,
      cardSuit: suitIndex,
    };
  }

  drawMajor(): DrawResult | null {
    return this.drawFromDeck(this.majorArcanaDeck, SUIT_NAME_TO_INDEX.major);
  }

  drawFromSuit(suitName: string): DrawResult | null {
    const suit = suitName.toLowerCase();
    const suitIndex = SUIT_NAME_TO_INDEX[suit];
    if (!suitIndex) {
      return null;
    }

    switch (suit) {
      case "cups":
        return this.drawFromDeck(this.cupsDeck, suitIndex);
      case "wands":
        return this.drawFromDeck(this.wandsDeck, suitIndex);
      case "swords":
        return this.drawFromDeck(this.swordsDeck, suitIndex);
      case "pentacles":
        return this.drawFromDeck(this.pentaclesDeck, suitIndex);
      case "major":
        return this.drawFromDeck(this.majorArcanaDeck, suitIndex);
      default:
        return null;
    }
  }

  drawMinorArcana(): DrawResult | null {
    const minorDecks = [
      this.cupsDeck,
      this.wandsDeck,
      this.swordsDeck,
      this.pentaclesDeck,
    ];
    const row = Math.floor(Math.random() * minorDecks.length);
    const selectedDeck = minorDecks[row];
    if (selectedDeck.length === 0) {
      return null;
    }

    const column = Math.floor(Math.random() * selectedDeck.length);
    return {
      cardName: selectedDeck[column],
      cardNumber: column + 1,
      cardSuit: row + 1,
    };
  }

  drawFullDeck(): DrawResult | null {
    const row = Math.floor(Math.random() * this.allDecks.length);
    const selectedDeck = this.allDecks[row];
    if (selectedDeck.length === 0) {
      return null;
    }

    const column = Math.floor(Math.random() * selectedDeck.length);
    return {
      cardName: selectedDeck[column],
      cardNumber: column + 1,
      cardSuit: row + 1,
    };
  }

  private initAlternateMode(): void {
    this.alternateDeckMode = true;
    this.alternateAvailableSuits = [1, 2, 3, 4, 5];
    for (let i = this.alternateAvailableSuits.length; i > 1; i -= 1) {
      const j = Math.floor(Math.random() * i);
      [this.alternateAvailableSuits[i - 1], this.alternateAvailableSuits[j]] = [
        this.alternateAvailableSuits[j],
        this.alternateAvailableSuits[i - 1],
      ];
    }
    this.alternateUsedCount = 0;
  }

  drawAlternate(): DrawResult | null {
    if (!this.alternateDeckMode) {
      this.initAlternateMode();
    }

    if (this.alternateUsedCount >= 5) {
      this.initAlternateMode();
    }

    this.alternateUsedCount += 1;
    const suitIndex = this.alternateAvailableSuits[this.alternateUsedCount - 1];
    const selectedDeck = this.allDecks[suitIndex - 1];
    if (!selectedDeck || selectedDeck.length === 0) {
      return null;
    }

    const column = Math.floor(Math.random() * selectedDeck.length);
    return {
      cardName: selectedDeck[column],
      cardNumber: column + 1,
      cardSuit: suitIndex,
    };
  }

  drawByFilter(filter: DeckFilter): DrawResult | null {
    switch (filter) {
      case "major":
        return this.drawMajor();
      case "minor":
        return this.drawMinorArcana();
      case "cups":
      case "wands":
      case "swords":
      case "pentacles":
        return this.drawFromSuit(filter);
      case "alternate":
        return this.drawAlternate();
      case "full":
      default:
        return this.drawFullDeck();
    }
  }

  rollInverted(): boolean {
    return Math.random() >= 0.51;
  }
}
