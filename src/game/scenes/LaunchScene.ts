import Phaser from "phaser";
import { GAME_HEIGHT, GAME_WIDTH } from "../config";
import { setChromeActions } from "../systems/GameInput";
import type { SoundManager } from "../systems/SoundManager";
import { initSceneCamera, onConfirm } from "../systems/phaserUtils";

export class LaunchScene extends Phaser.Scene {
  private proceeded = false;

  constructor() {
    super({ key: "LaunchScene" });
  }

  create(): void {
    initSceneCamera(this);
    this.proceeded = false;

    this.add.image(GAME_WIDTH / 2, GAME_HEIGHT / 2, "launch");

    setChromeActions({ confirm: true, shuffle: false, zoom: false, back: false });
    onConfirm(this, () => this.proceed());
    this.events.once(Phaser.Scenes.Events.SHUTDOWN, () => {
      setChromeActions({ confirm: false, shuffle: false, zoom: false, back: false });
    });
  }

  private proceed(): void {
    if (this.proceeded) {
      return;
    }
    this.proceeded = true;

    const sound = this.registry.get("sound") as SoundManager;
    sound.unlock();
    sound.startBgMusic(true);
    this.scene.start("TitleScene");
  }
}
