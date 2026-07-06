import Phaser from "phaser";
import { GAME_HEIGHT, GAME_WIDTH } from "../config";
import type { SoundManager } from "../systems/SoundManager";
import { initSceneCamera } from "../systems/phaserUtils";

export class LaunchScene extends Phaser.Scene {
  constructor() {
    super({ key: "LaunchScene" });
  }

  create(): void {
    initSceneCamera(this);

    this.add.image(GAME_WIDTH / 2, GAME_HEIGHT / 2, "launch");

    this.input.once("pointerdown", () => this.proceed());
    this.input.keyboard?.once("keydown", () => this.proceed());
  }

  private proceed(): void {
    const sound = this.registry.get("sound") as SoundManager;
    sound.unlock();
    sound.startBgMusic(true);
    this.scene.start("TitleScene");
  }
}
