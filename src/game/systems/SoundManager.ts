import Phaser from "phaser";

export class SoundManager {
  private unlocked = false;
  private crankSound?: Phaser.Sound.BaseSound;

  constructor(private readonly scene: Phaser.Scene) {}

  unlock(): void {
    if (this.unlocked) {
      return;
    }

    if (this.scene.sound.locked) {
      this.scene.sound.unlock();
    }
    this.unlocked = true;
  }

  playSfx(key: string, config?: Phaser.Types.Sound.SoundConfig): void {
    if (!this.unlocked) {
      return;
    }
    if (this.scene.cache.audio.exists(key)) {
      this.scene.sound.play(key, config);
    }
  }

  startCrankLoop(): void {
    if (!this.unlocked || !this.scene.cache.audio.exists("sfx-crank")) {
      return;
    }

    if (!this.crankSound || !this.crankSound.isPlaying) {
      this.crankSound = this.scene.sound.add("sfx-crank", { loop: true, volume: 0.65 });
      this.crankSound.play();
    }
  }

  stopCrankLoop(): void {
    this.crankSound?.stop();
    this.crankSound?.destroy();
    this.crankSound = undefined;
  }

  destroy(): void {
    this.stopCrankLoop();
  }
}
