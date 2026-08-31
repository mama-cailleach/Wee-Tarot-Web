import Phaser from "phaser";
import { bindBack, setChromeActions } from "../systems/GameInput";
import { createDinahSprite } from "../systems/dinah";
import type { SoundManager } from "../systems/SoundManager";
import {
  createWrappedText,
  initSceneCamera,
  onConfirm,
  type UiText,
} from "../systems/phaserUtils";

const TEXT_BASE_Y = 182;
const SCROLL_BASE_Y = 170;
const OSC_AMPLITUDE = 3.7;
const OSC_SPEED = 2.5;
const SCROLL_REVEAL_DELAY_MS = 3200;

/** Placeholder How To copy — replace when final tutorial text is ready. */
export const HOW_TO_LINES = [
  "Ah yes, curious one... I felt your energy long before you stepped in.",
  "First time? Don't fret. I'll hold the veil open for you.",
  "One card.",
  "One glimpse beyond what most dare to seek.",
  "Shuffle the deck. Let fate crack it's knuckles.",
  "While you shuffle, the cards are listening.", 
  "This is a single-card reading. Simple, but never shallow.",
  "Full deck or Major Arcana only? Set your intentions wisely.",
  "Once the card reveals itself...",
  "I listen. The whispers don't speak to just anyone.",
  "I won't stop you squinting at fate. Advance only if you're ready.",
  "Your fortune will rise like mist, or smoke, or something you forgot...",
  "At the journey's end, you will be allowed to choose: ",
  "Look back at the Cloth one last time, or step away.",
  "When the spirits go quiet, you may seek another reading.",
  "But remember, darling...",
  "The cards don't lie.",
  "Even when you do."

];

export class HowToScene extends Phaser.Scene {
  private lineIndex = 0;
  private textBox?: UiText;
  private scrollSprite?: Phaser.GameObjects.Image;
  private canAdvance = false;
  private oscillationStart?: number;

  constructor() {
    super({ key: "HowToScene" });
  }

  create(): void {
    initSceneCamera(this);

    this.lineIndex = 0;
    this.canAdvance = false;
    this.oscillationStart = undefined;

    createDinahSprite(this);

    this.scrollSprite = this.add.image(202, 300, "scroll-box").setDepth(2).setAlpha(0);

    setChromeActions({
      confirm: false,
      shuffle: false,
      zoom: false,
      back: false,
      navigate: false,
    });

    onConfirm(this, () => this.handleConfirm());
    bindBack(this, () => this.returnToSettings(true));

    this.tweens.add({
      targets: this.scrollSprite,
      y: SCROLL_BASE_Y,
      alpha: 1,
      duration: 900,
      ease: "Cubic.easeOut",
      delay: SCROLL_REVEAL_DELAY_MS,
      onComplete: () => {
        this.canAdvance = true;
        setChromeActions({
          confirm: true,
          confirmLabel: "Next",
          shuffle: false,
          zoom: false,
          back: true,
          backLabel: "Back",
          navigate: false,
        });
        this.showCurrentLine();
        this.oscillationStart = this.time.now;
      },
    });

    this.events.once(Phaser.Scenes.Events.SHUTDOWN, () => {
      setChromeActions({
        confirm: false,
        shuffle: false,
        zoom: false,
        back: false,
        navigate: false,
      });
    });
  }

  private soundManager(): SoundManager {
    return this.registry.get("sound") as SoundManager;
  }

  private showCurrentLine(): void {
    this.textBox?.destroy();
    const line = HOW_TO_LINES[this.lineIndex] ?? "";
    this.textBox = createWrappedText(this, 190, TEXT_BASE_Y, line, 310, {
      fontSize: 20,
      color: "#000000",
    });
  }

  private handleConfirm(): void {
    if (!this.canAdvance) {
      return;
    }

    if (this.lineIndex < HOW_TO_LINES.length - 1) {
      this.lineIndex += 1;
      this.showCurrentLine();
      return;
    }

    this.returnToSettings(false);
  }

  private returnToSettings(fromBack: boolean): void {
    if (fromBack && !this.canAdvance) {
      return;
    }
    if (fromBack) {
      this.soundManager().playSfx("sfx-b-button", { volume: 0.5 });
    } else {
      this.soundManager().playABut();
    }
    this.scene.start("SettingsScene");
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
