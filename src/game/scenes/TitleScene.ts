import Phaser from "phaser";
import type { SoundManager } from "../systems/SoundManager";
import { createWrappedText, initSceneCamera, type UiText } from "../systems/phaserUtils";

const TITLE_ANIM_KEY = "title-intro";
const TITLE_ANIM_FRAMES = 34;
const TITLE_ANIM_FRAME_RATE = 20;
const TITLE_END_HOLD_MS = 500;

export class TitleScene extends Phaser.Scene {
  private titleSprite?: Phaser.GameObjects.Sprite;
  private prompt?: UiText;
  private ready = false;
  private animating = false;
  private introCompletePending = false;
  private introHoldUntil = 0;
  private keyA?: Phaser.Input.Keyboard.Key;

  constructor() {
    super({ key: "TitleScene" });
  }

  create(): void {
    initSceneCamera(this);
    this.cameras.main.setBackgroundColor("#ffffff");
    this.ready = false;
    this.animating = false;
    this.introCompletePending = false;
    this.introHoldUntil = 0;

    console.log("[TitleScene] create");

    const sound = this.registry.get("sound") as SoundManager;
    sound.startBgMusic(true);

    if (this.textures.exists("title-anim-sheet")) {
      this.titleSprite = this.add
        .sprite(200, 120, "title-anim-sheet", 0)
        .setDepth(1)
        .setFrame(0);

      if (!this.anims.exists(TITLE_ANIM_KEY)) {
        const frameTotal = this.textures.get("title-anim-sheet").frameTotal;
        this.anims.create({
          key: TITLE_ANIM_KEY,
          frames: this.anims.generateFrameNumbers("title-anim-sheet", {
            start: 0,
            end: Math.min(TITLE_ANIM_FRAMES - 1, frameTotal - 1),
          }),
          frameRate: TITLE_ANIM_FRAME_RATE,
          repeat: 0,
        });
      }
    }

    this.prompt = createWrappedText(this, 198, 210, "Tap to start", 360, {
      fontSize: 20,
    });

    this.input.keyboard?.on("keydown-SPACE", () => this.begin());
    this.input.keyboard?.on("keydown-ENTER", () => this.begin());
    this.input.on("pointerdown", () => this.begin());

    if (this.input.keyboard) {
      this.keyA = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.A);
    }

    this.ready = true;
  }

  update(): void {
    if (this.keyA && Phaser.Input.Keyboard.JustDown(this.keyA)) {
      this.goToMenu();
    }

    if (!this.animating) {
      return;
    }

    if (this.introCompletePending) {
      if (this.time.now >= this.introHoldUntil) {
        this.goToMenu();
      }
      return;
    }

    const animState = this.titleSprite?.anims;
    if (animState?.currentAnim?.key === TITLE_ANIM_KEY && !animState.isPlaying) {
      this.onTitleIntroComplete();
    }
  }

  private begin(): void {
    if (!this.ready || this.animating) {
      return;
    }

    this.animating = true;
    this.prompt?.destroy();
    this.prompt = undefined;

    const sound = this.registry.get("sound") as SoundManager;
    sound.unlock();
    sound.playSfx("sfx-cards-fast", { volume: 0.45 });

    if (this.titleSprite && this.anims.exists(TITLE_ANIM_KEY)) {
      this.titleSprite.play(TITLE_ANIM_KEY);
      return;
    }

    this.goToMenu();
  }

  private onTitleIntroComplete(): void {
    if (this.introCompletePending) {
      return;
    }

    this.introCompletePending = true;
    this.titleSprite?.setFrame(TITLE_ANIM_FRAMES - 1);
    this.introHoldUntil = this.time.now + TITLE_END_HOLD_MS;
  }

  private goToMenu(): void {
    const sound = this.registry.get("sound") as SoundManager;
    sound.leaveTitleMusicLoop();
    console.log("[TitleScene] → MenuScene (Phaser scene.start)");
    this.scene.start("MenuScene");
  }
}