import Phaser from "phaser";
import { buildLines } from "../data/oneCardReadingText";
import type { ReadingResult } from "../data/types";
import { bindBack, setChromeActions } from "../systems/GameInput";
import {
  createDinahSprite,
  DINAH_LEAVE_POST_END,
  playDinahLeave,
} from "../systems/dinah";
import type { SoundManager } from "../systems/SoundManager";
import { createWrappedText, initSceneCamera, onConfirm, type UiText } from "../systems/phaserUtils";

interface OneCardPostData {
  reading: ReadingResult;
}

// Matches the Playdate BaseSpreadPostScene oscillation.
const TEXT_BASE_Y = 182;
const SCROLL_BASE_Y = 170;
const OSC_AMPLITUDE = 3.7;
const OSC_SPEED = 2.5;
const SCROLL_REVEAL_DELAY_MS = 3200;

export class OneCardPostScene extends Phaser.Scene {
  private reading?: ReadingResult;
  private lines: string[] = [];
  private lineIndex = 0;
  private textBox?: UiText;
  private scrollSprite?: Phaser.GameObjects.Image;
  private dinahSprite?: Phaser.GameObjects.Sprite;
  private canAdvance = false;
  private oscillationStart?: number;
  private leaving = false;

  constructor() {
    super({ key: "OneCardPostScene" });
  }

  init(data: OneCardPostData): void {
    this.reading = data.reading;
  }

  create(): void {
    initSceneCamera(this);

    if (!this.reading) {
      this.scene.start("MenuScene");
      return;
    }

    this.lineIndex = 0;
    this.canAdvance = false;
    this.oscillationStart = undefined;
    this.leaving = false;

    this.dinahSprite = createDinahSprite(this);

    // One-card readings do not show a card preview (config.enableCardPreviews = false).
    this.lines = buildLines(this.reading.cardName, this.reading.inverted).lines;

    this.scrollSprite = this.add.image(202, 300, "scroll-box").setDepth(2).setAlpha(0);

    setChromeActions({ confirm: false, shuffle: false, zoom: false, back: false });
    onConfirm(this, () => this.advance());
    bindBack(this, () => this.goBackToCardView());
    this.events.once(Phaser.Scenes.Events.SHUTDOWN, () => {
      setChromeActions({ confirm: false, shuffle: false, zoom: false, back: false });
    });

    this.tweens.add({
      targets: this.scrollSprite,
      y: SCROLL_BASE_Y,
      alpha: 1,
      duration: 900,
      ease: "Cubic.easeOut",
      delay: SCROLL_REVEAL_DELAY_MS,
      onComplete: () => {
        this.canAdvance = true;
        this.showCurrentLine();
        this.refreshChrome();
        this.oscillationStart = this.time.now;
      },
    });
  }

  private soundManager(): SoundManager {
    return this.registry.get("sound") as SoundManager;
  }

  private isLastLine(): boolean {
    return this.lineIndex >= this.lines.length - 1;
  }

  private refreshChrome(): void {
    setChromeActions({
      confirm: this.canAdvance,
      confirmLabel: this.isLastLine() ? "Leave" : "Next",
      shuffle: false,
      zoom: false,
      back: this.canAdvance && this.isLastLine(),
      backLabel: "Cloth",
    });
  }

  private showCurrentLine(): void {
    this.textBox?.destroy();
    const line = this.lines[this.lineIndex] ?? "";
    this.textBox = createWrappedText(this, 190, TEXT_BASE_Y, line.replace(/\*/g, ""), 310, {
      fontSize: 20,
      color: "#323027",
    });
  }

  private advance(): void {
    if (!this.canAdvance) {
      return;
    }

    if (this.lineIndex < this.lines.length - 1) {
      this.lineIndex += 1;
      this.showCurrentLine();
      this.refreshChrome();
      return;
    }

    this.finishReading();
  }

  private goBackToCardView(): void {
    if (!this.canAdvance || !this.isLastLine() || !this.reading) {
      return;
    }

    this.soundManager().playABut();
    this.scene.start("CardReviewScene", { reading: this.reading });
  }

  private finishReading(): void {
    if (this.leaving) {
      return;
    }

    this.leaving = true;
    this.soundManager().playABut();
    this.soundManager().playSfx("sfx-tuin", { volume: 0.5 });
    setChromeActions({ confirm: false, shuffle: false, zoom: false, back: false });

    if (!this.dinahSprite) {
      this.scene.start("MenuScene");
      return;
    }

    playDinahLeave(this, this.dinahSprite, DINAH_LEAVE_POST_END, () => {
      this.scene.start("MenuScene");
    });
  }

  update(): void {
    if (this.oscillationStart === undefined) {
      return;
    }

    const elapsed = (this.time.now - this.oscillationStart) / 1000;
    const offset = OSC_AMPLITUDE * Math.sin(elapsed * OSC_SPEED);

    this.textBox?.setY(TEXT_BASE_Y + offset);
    this.scrollSprite?.setY(SCROLL_BASE_Y + offset);
  }
}
