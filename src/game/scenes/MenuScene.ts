import Phaser from "phaser";
import { setChromeActions } from "../systems/GameInput";
import type { SoundManager } from "../systems/SoundManager";
import {
  addGameText,
  createWrappedText,
  initSceneCamera,
  onConfirm,
  type UiText,
} from "../systems/phaserUtils";

const DINAH_IDLE_ANIM_KEY = "dinah-idle";
const DINAH_IDLE_FRAMES = 6;
const DINAH_IDLE_FRAME_RATE = 8;

const TEXT_BASE_Y = 182;
const SCROLL_BASE_Y = 170;
const OSC_AMPLITUDE = 3.7;
const OSC_SPEED = 2.5;
const SCROLL_REVEAL_DELAY_MS = 3200;

const INTRO_LINES = [
  "...",
  "Welcome to my humble abode, I've been expecting you.",
  "Yes, yes... I can see... Your future is bright.",
  "Care for a reading, darling?",
  "Please...",
  "Have a seat...",
  "Don't be scared...",
  "I speak only what I see, but to find more meaning in the cards is up to you.",
];

const MENU_INTRO_SEEN_KEY = "menuIntroSeen";

type MenuMode = "intro" | "menu";

export class MenuScene extends Phaser.Scene {
  private mode: MenuMode = "intro";
  private lines: string[] = INTRO_LINES;
  private lineIndex = 0;
  private textBox?: UiText;
  private scrollSprite?: Phaser.GameObjects.Image;
  private dinahSprite?: Phaser.GameObjects.Sprite;
  private canAdvance = false;
  private oscillationStart?: number;
  private menuObjects: Phaser.GameObjects.GameObject[] = [];

  constructor() {
    super({ key: "MenuScene" });
  }

  create(): void {
    initSceneCamera(this);

    this.lineIndex = 0;
    this.canAdvance = false;
    this.oscillationStart = undefined;
    this.menuObjects = [];

    this.setupDinah();

    setChromeActions({ confirm: false, shuffle: false, zoom: false, back: false });
    onConfirm(this, () => this.handleConfirm());
    this.events.once(Phaser.Scenes.Events.SHUTDOWN, () => {
      setChromeActions({ confirm: false, shuffle: false, zoom: false, back: false });
    });

    if (this.registry.get(MENU_INTRO_SEEN_KEY)) {
      this.showMenuOptions();
      return;
    }

    this.mode = "intro";
    this.scrollSprite = this.add.image(202, 300, "scroll-box").setDepth(2).setAlpha(0);

    this.tweens.add({
      targets: this.scrollSprite,
      y: SCROLL_BASE_Y,
      alpha: 1,
      duration: 900,
      ease: "Cubic.easeOut",
      delay: SCROLL_REVEAL_DELAY_MS,
      onComplete: () => {
        this.canAdvance = true;
        setChromeActions({ confirm: true, shuffle: false, zoom: false, back: false });
        this.showCurrentLine();
        this.oscillationStart = this.time.now;
      },
    });
  }

  private setupDinah(): void {
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
  }

  private soundManager(): SoundManager {
    return this.registry.get("sound") as SoundManager;
  }

  private showCurrentLine(): void {
    this.textBox?.destroy();
    const line = this.lines[this.lineIndex] ?? "";
    this.textBox = createWrappedText(this, 190, TEXT_BASE_Y, line, 310, {
      fontSize: 20,
      color: "#000000",
    });
  }

  private handleConfirm(): void {
    if (this.mode === "menu") {
      this.soundManager().playSfx("sfx-a-but", { volume: 0.5 });
      this.scene.start("OneCardGameScene");
      return;
    }

    if (!this.canAdvance) {
      return;
    }

    if (this.lineIndex < this.lines.length - 1) {
      this.lineIndex += 1;
      this.showCurrentLine();
      return;
    }

    this.enterMenu();
  }

  private enterMenu(): void {
    this.textBox?.destroy();
    this.textBox = undefined;
    this.scrollSprite?.destroy();
    this.scrollSprite = undefined;
    this.oscillationStart = undefined;

    this.registry.set(MENU_INTRO_SEEN_KEY, true);
    this.showMenuOptions();
  }

  private showMenuOptions(): void {
    this.mode = "menu";
    this.canAdvance = true;
    setChromeActions({ confirm: true, shuffle: false, zoom: false, back: false });

    const settingsLabel = addGameText(this, 65, 220, "menu", {
      fontSize: 20,
    }).setOrigin(0.5, 0.5);
    this.menuObjects.push(settingsLabel);

    this.time.delayedCall(34, () => {
      const readingLabel = addGameText(this, 325, 220, "reading", {
        fontSize: 20,
      }).setOrigin(0.5, 0.5);
      this.menuObjects.push(readingLabel);

      this.menuObjects.push(this.makeMenuButton("<", 16, 223, 14));
      this.menuObjects.push(this.makeMenuButton(">", 384, 223, 14));
    });
  }

  private makeMenuButton(letter: string, x: number, y: number, radius: number): Phaser.GameObjects.Container {
    const container = this.add.container(x, y).setDepth(5);

    const circle = this.add.circle(0, 0, radius, 0xa9a9a9).setStrokeStyle(2, 0x323027);
    const label = addGameText(this, 0, 0, letter, {
      fontSize: 20,
      color: "#323027",
      align: "center",
    }).setOrigin(0.5, 0.5);

    container.add([circle, label]);
    return container;
  }

  update(): void {
    if (this.mode !== "intro" || this.oscillationStart === undefined) {
      return;
    }

    const elapsed = (this.time.now - this.oscillationStart) / 1000;
    const offset = OSC_AMPLITUDE * Math.sin(elapsed * OSC_SPEED);

    this.textBox?.setY(TEXT_BASE_Y + offset);
    this.scrollSprite?.setY(SCROLL_BASE_Y + offset);
  }
}
