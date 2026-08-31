import Phaser from "phaser";
import { GAME_HEIGHT, GAME_WIDTH } from "../config";
import { setChromeActions } from "../systems/GameInput";
import type { SoundManager } from "../systems/SoundManager";
import { initSceneCamera, onConfirm } from "../systems/phaserUtils";

const SPLASH_HOLD_MS = 2000;

export class LaunchScene extends Phaser.Scene {
  private proceeded = false;
  private canStart = false;

  constructor() {
    super({ key: "LaunchScene" });
  }

  create(): void {
    initSceneCamera(this);
    this.proceeded = false;
    this.canStart = false;

    const splash = this.add.image(GAME_WIDTH / 2, GAME_HEIGHT / 2, "launch");

    setChromeActions({
      confirm: false,
      shuffle: false,
      zoom: false,
      back: false,
      start: false,
    });
    onConfirm(this, () => this.proceed());
    this.events.once(Phaser.Scenes.Events.SHUTDOWN, () => {
      setChromeActions({
        confirm: false,
        shuffle: false,
        zoom: false,
        back: false,
        start: false,
      });
    });

    this.time.delayedCall(SPLASH_HOLD_MS, () => {
      if (this.proceeded) {
        return;
      }
      splash.setTexture("launch-prompt");
      this.canStart = true;
      setChromeActions({
        confirm: true,
        confirmLabel: "Launch",
        shuffle: false,
        zoom: false,
        back: false,
        start: false,
      });
    });
  }

  private proceed(): void {
    if (this.proceeded || !this.canStart) {
      return;
    }
    this.proceeded = true;

    const sound = this.registry.get("sound") as SoundManager;
    sound.unlock();
    sound.startBgMusic(true);
    this.scene.start("TitleScene");
  }
}
