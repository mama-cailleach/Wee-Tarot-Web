import Phaser from "phaser";
import { buildLines } from "../data/oneCardReadingText";
import type { ReadingResult } from "../data/types";
import { setChromeActions } from "../systems/GameInput";
import type { SoundManager } from "../systems/SoundManager";
import { createWrappedText, initSceneCamera, onConfirm, type UiText } from "../systems/phaserUtils";

interface OneCardPostData {
  reading: ReadingResult;
}

// Matches the Playdate BaseSpreadPostScene oscillation.
const DINAH_IDLE_ANIM_KEY = "dinah-idle";
const DINAH_IDLE_FRAMES = 6;
const DINAH_IDLE_FRAME_RATE = 8;

const TEXT_BASE_Y = 182;
const SCROLL_BASE_Y = 170;
const ICON_BASE_Y = 220;
const OSC_AMPLITUDE = 3.7;
const OSC_SPEED = 2.5;
const SCROLL_REVEAL_DELAY_MS = 3200;

export class OneCardPostScene extends Phaser.Scene {
  private reading?: ReadingResult;
  private lines: string[] = [];
  private lineIndex = 0;
  private textBox?: UiText;
  private scrollSprite?: Phaser.GameObjects.Image;
  private iconSprite?: Phaser.GameObjects.Image;
  private dinahSprite?: Phaser.GameObjects.Sprite;
  private canAdvance = false;
  private oscillationStart?: number;

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

    this.dinahSprite = this.add.sprite(200, 120, "dinah-bg", 0).setDepth(0).setAlpha(0.9);

    if (!this.anims.exists(DINAH_IDLE_ANIM_KEY)) {
      const frameTotal = this.textures.get("dinah-bg").frameTotal;
      this.anims.create({
        key: DINAH_IDLE_ANIM_KEY,
        frames: this.anims.generateFrameNumbers("dinah-bg", {
          start: 0,
          end: Math.min(DINAH_IDLE_FRAMES - 1, frameTotal - 1),
        }),
        frameRate: DINAH_IDLE_FRAME_RATE,
        yoyo: true,
        repeat: -1,
      });
    }

    this.dinahSprite.play(DINAH_IDLE_ANIM_KEY);

    // One-card readings do not show a card preview (config.enableCardPreviews = false).
    this.lines = buildLines(this.reading.cardName, this.reading.inverted).lines;

    this.scrollSprite = this.add.image(202, 300, "scroll-box").setDepth(2).setAlpha(0);

    setChromeActions({ confirm: false, shuffle: false });
    onConfirm(this, () => this.advance());
    this.events.once(Phaser.Scenes.Events.SHUTDOWN, () => {
      setChromeActions({ confirm: false, shuffle: false });
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
        setChromeActions({ confirm: true, shuffle: false });
        this.showCurrentLine();
        this.showAdvanceHint();
        this.oscillationStart = this.time.now;
      },
    });
  }

  private soundManager(): SoundManager {
    return this.registry.get("sound") as SoundManager;
  }

  private showCurrentLine(): void {
    this.textBox?.destroy();
    const line = this.lines[this.lineIndex] ?? "";
    this.textBox = createWrappedText(this, 190, TEXT_BASE_Y, line.replace(/\*/g, ""), 310, {
      fontSize: 20,
      color: "#323027",
    });
  }

  private showAdvanceHint(): void {
    this.iconSprite = this.add.image(360, ICON_BASE_Y, "icon-tri").setDepth(4).setScale(1.2);
  }

  private advance(): void {
    if (!this.canAdvance) {
      return;
    }

    if (this.lineIndex < this.lines.length - 1) {
      this.lineIndex += 1;
      this.showCurrentLine();
      return;
    }

    this.finishReading();
  }

  private finishReading(): void {
    this.soundManager().playSfx("sfx-a-but", { volume: 0.5 });
    this.scene.start("MenuScene");
  }

  update(): void {
    if (this.oscillationStart === undefined) {
      return;
    }

    const elapsed = (this.time.now - this.oscillationStart) / 1000;
    const offset = OSC_AMPLITUDE * Math.sin(elapsed * OSC_SPEED);

    this.textBox?.setY(TEXT_BASE_Y + offset);
    this.scrollSprite?.setY(SCROLL_BASE_Y + offset);
    this.iconSprite?.setY(ICON_BASE_Y + offset);
  }
}
