import Phaser from "phaser";
import { getCardImageUrl } from "../config";
import { buildLines } from "../data/oneCardReadingText";
import type { ReadingResult } from "../data/types";
import type { SoundManager } from "../systems/SoundManager";
import { confirmPressed, createWrappedText, initSceneCamera, type UiText } from "../systems/phaserUtils";

interface OneCardPostData {
  reading: ReadingResult;
}

export class OneCardPostScene extends Phaser.Scene {
  private reading?: ReadingResult;
  private lines: string[] = [];
  private lineIndex = 0;
  private textBox?: UiText;
  private scrollSprite?: Phaser.GameObjects.Image;
  private canAdvance = false;
  private cardSprite?: Phaser.GameObjects.Image;

  constructor() {
    super({ key: "OneCardPostScene" });
  }

  init(data: OneCardPostData): void {
    this.reading = data.reading;
  }

  create(): void {
    initSceneCamera(this);

    if (!this.reading) {
      this.scene.start("TitleScene");
      return;
    }

    this.lineIndex = 0;
    this.canAdvance = false;

    this.add.sprite(200, 133, "dinah-bg", 0).setDepth(0).setAlpha(0.9);

    const cardKey = `card-zoom-${this.reading.cardSuit}-${this.reading.cardNumber}`;
    const cardUrl = getCardImageUrl(this.reading.cardNumber, this.reading.cardSuit, true);

    const showReadingUi = () => {
      this.scrollSprite = this.add.image(202, 220, "scroll-box").setDepth(2).setAlpha(0);

      this.tweens.add({
        targets: this.scrollSprite,
        y: 170,
        alpha: 1,
        duration: 900,
        ease: "Cubic.easeOut",
        delay: 3200,
        onComplete: () => {
          this.canAdvance = true;
          this.showCurrentLine();
          this.showAdvanceHint();
        },
      });
    };

    const placeCardPreview = (textureKey: string) => {
      this.cardSprite = this.add
        .image(200, 74, textureKey)
        .setDepth(1)
        .setScale(0.55);

      if (this.reading?.inverted) {
        this.cardSprite.setAngle(180);
      }

      const built = buildLines(this.reading!.cardName, this.reading!.inverted);
      this.lines = built.lines;
      showReadingUi();
    };

    if (!this.textures.exists(cardKey)) {
      this.load.image(cardKey, cardUrl);
      this.load.once(Phaser.Loader.Events.COMPLETE, () => placeCardPreview(cardKey));
      this.load.start();
    } else {
      placeCardPreview(cardKey);
    }
  }

  private soundManager(): SoundManager {
    return this.registry.get("sound") as SoundManager;
  }

  private showCurrentLine(): void {
    this.textBox?.destroy();
    const line = this.lines[this.lineIndex] ?? "";
    this.textBox = createWrappedText(this, 190, 182, line.replace(/\*/g, ""), 310, {
      fontSize: 13,
    });

    this.tweens.add({
      targets: this.textBox,
      y: "+=3",
      duration: 900,
      yoyo: true,
      repeat: -1,
      ease: "Sine.easeInOut",
    });
  }

  private showAdvanceHint(): void {
    this.add.image(360, 220, "icon-tri").setDepth(4).setScale(1.2);
  }

  private finishReading(): void {
    this.soundManager().playSfx("sfx-a-but", { volume: 0.5 });
    this.scene.start("TitleScene");
  }

  update(): void {
    if (!this.canAdvance) {
      return;
    }

    if (!confirmPressed(this)) {
      return;
    }

    if (this.lineIndex < this.lines.length - 1) {
      this.lineIndex += 1;
      this.showCurrentLine();
      return;
    }

    this.finishReading();
  }
}
