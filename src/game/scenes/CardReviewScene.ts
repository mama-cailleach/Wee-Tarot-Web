import Phaser from "phaser";
import { getCardImageUrl } from "../config";
import type { ReadingResult } from "../data/types";
import { bindZoom, setChromeActions } from "../systems/GameInput";
import type { SoundManager } from "../systems/SoundManager";
import { fitImageToGameFrame, initSceneCamera, loadTextureFromUrl, onConfirm } from "../systems/phaserUtils";

interface CardReviewData {
  reading: ReadingResult;
}

/** Final peek at the drawn card on the cloth after the fortune text. Confirm → menu. */
export class CardReviewScene extends Phaser.Scene {
  private reading?: ReadingResult;
  private cardSprite?: Phaser.GameObjects.Image;
  private cardZoomed = false;
  private zoomToggleBusy = false;
  private canLeave = false;

  constructor() {
    super({ key: "CardReviewScene" });
  }

  init(data: CardReviewData): void {
    this.reading = data.reading;
  }

  create(): void {
    initSceneCamera(this);

    if (!this.reading) {
      this.scene.start("MenuScene");
      return;
    }

    this.cardZoomed = false;
    this.zoomToggleBusy = false;
    this.canLeave = false;

    this.add.image(200, 120, "darkcloth").setDepth(0);
    this.add.image(200, 120, "placement-diamond").setDepth(2);

    setChromeActions({ confirm: false, shuffle: false, zoom: false, back: false });
    onConfirm(this, () => this.leaveToMenu(), { canvasTap: false });
    bindZoom(this, () => this.toggleCardZoom());
    this.events.once(Phaser.Scenes.Events.SHUTDOWN, () => {
      setChromeActions({ confirm: false, shuffle: false, zoom: false, back: false });
    });

    this.loadCardTexture(false, (key) => this.placeCard(key));
  }

  private soundManager(): SoundManager {
    return this.registry.get("sound") as SoundManager;
  }

  private cardTextureKey(zoomed: boolean): string {
    if (!this.reading) {
      return "";
    }
    const base = `card-${this.reading.cardSuit}-${this.reading.cardNumber}`;
    return zoomed ? `${base}-zoom` : base;
  }

  private loadCardTexture(zoomed: boolean, onReady: (key: string) => void): void {
    if (!this.reading) {
      return;
    }

    const key = this.cardTextureKey(zoomed);
    if (this.textures.exists(key)) {
      onReady(key);
      return;
    }

    const url = getCardImageUrl(this.reading.cardNumber, this.reading.cardSuit, zoomed);
    loadTextureFromUrl(this, key, url, onReady);
  }

  private placeCard(textureKey: string): void {
    if (!this.reading) {
      return;
    }

    this.cardSprite = this.add.image(200, 120, textureKey).setDepth(4);
    fitImageToGameFrame(this.cardSprite);
    if (this.reading.inverted) {
      this.cardSprite.setAngle(180);
    }

    this.canLeave = true;
    setChromeActions({
      confirm: true,
      confirmLabel: "Menu",
      shuffle: false,
      zoom: true,
      back: false,
    });
  }

  private toggleCardZoom(): void {
    if (!this.reading || !this.cardSprite || this.zoomToggleBusy) {
      return;
    }

    const nextZoomed = !this.cardZoomed;
    const textureKey = this.cardTextureKey(nextZoomed);

    const apply = (): void => {
      this.cardSprite?.setTexture(textureKey);
      fitImageToGameFrame(this.cardSprite);
      if (this.reading?.inverted) {
        this.cardSprite?.setAngle(180);
      }
      this.cardZoomed = nextZoomed;
      this.zoomToggleBusy = false;
    };

    if (this.textures.exists(textureKey)) {
      apply();
      return;
    }

    this.zoomToggleBusy = true;
    this.loadCardTexture(nextZoomed, (key) => {
      if (!this.textures.exists(key) || !this.cardSprite) {
        this.zoomToggleBusy = false;
        return;
      }
      apply();
    });
  }

  private leaveToMenu(): void {
    if (!this.canLeave) {
      return;
    }
    this.soundManager().playABut();
    this.scene.start("MenuScene");
  }
}
