// AUTO-GENERATED â€” run scripts/export-content.ps1 or npm run export:data

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
