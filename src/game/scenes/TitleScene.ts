import Phaser from "phaser";
import { fadeInIfNeeded, switchScene } from "../systems/SceneTransitions";
import type { SoundManager } from "../systems/SoundManager";
import { createWrappedText, registerGridFrames } from "../systems/phaserUtils";

export class TitleScene extends Phaser.Scene {
  private titleSprite?: Phaser.GameObjects.Sprite;
  private prompt?: Phaser.GameObjects.Text;
  private ready = false;

  constructor() {
    super({ key: "TitleScene" });
  }

  create(): void {
    fadeInIfNeeded(this);
    this.cameras.main.setBackgroundColor("#ffffff");

    if (this.textures.exists("title-anim-sheet")) {
      const frameCount = registerGridFrames(this, "title-anim-sheet", 400, 391);
      this.titleSprite = this.add.sprite(200, 120, "title-anim-sheet", 0).setDepth(1);

      if (!this.anims.exists("title-loop")) {
        this.anims.create({
          key: "title-loop",
          frames: this.anims.generateFrameNumbers("title-anim-sheet", {
            start: 0,
            end: Math.max(0, frameCount - 1),
          }),
          frameRate: 12,
          repeat: -1,
        });
      }
      this.titleSprite.play("title-loop");
    } else {
      this.add
        .text(200, 100, "Wee Tarot", {
          fontFamily: "Georgia, serif",
          fontSize: "32px",
          color: "#000000",
        })
        .setOrigin(0.5);
    }

    this.prompt = createWrappedText(this, 200, 215, "Tap or press Space to begin", 360, {
      fontSize: "12px",
    });

    this.tweens.add({
      targets: this.prompt,
      alpha: { from: 1, to: 0.25 },
      duration: 700,
      yoyo: true,
      repeat: -1,
    });

    this.input.on("pointerdown", () => this.begin());
    this.input.keyboard?.on("keydown-SPACE", () => this.begin());
    this.input.keyboard?.on("keydown-ENTER", () => this.begin());

    this.ready = true;
  }

  private begin(): void {
    if (!this.ready || this.registry.get("sceneTransitioning")) {
      return;
    }

    const sound = this.registry.get("sound") as SoundManager;
    sound.unlock();
    sound.playSfx("sfx-a-but", { volume: 0.5 });

    switchScene(this, "OneCardGameScene");
  }
}
