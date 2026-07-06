import Phaser from "phaser";

const BG_MUSIC_KEY = "music-bg";
const BG_MUSIC_VOLUME = 0.9;
const BG_MUSIC_TITLE_LOOP_MARKER = "title-loop";
const BG_MUSIC_TITLE_LOOP_DURATION_SEC = 22;

export class SoundManager {
  private unlocked = false;
  private crankSound?: Phaser.Sound.BaseSound;
  private bgMusic?: Phaser.Sound.WebAudioSound;
  private bgMusicTitleLoop = false;

  constructor(private readonly scene: Phaser.Scene) {}

  unlock(): void {
    if (this.unlocked) {
      return;
    }

    if (this.scene.sound.locked) {
      this.scene.sound.unlock();
    }
    this.unlocked = true;
    this.startBgMusic(this.bgMusicTitleLoop);
  }

  /** Start looping background music once audio is unlocked. */
  startBgMusic(titleLoop = false): void {
    if (!this.unlocked || !this.scene.cache.audio.exists(BG_MUSIC_KEY)) {
      if (titleLoop) {
        this.bgMusicTitleLoop = true;
      }
      return;
    }

    this.bgMusicTitleLoop = titleLoop;

    if (!this.bgMusic) {
      this.bgMusic = this.scene.sound.add(BG_MUSIC_KEY, {
        loop: true,
        volume: BG_MUSIC_VOLUME,
      }) as Phaser.Sound.WebAudioSound;

      this.bgMusic.addMarker({
        name: BG_MUSIC_TITLE_LOOP_MARKER,
        start: 0,
        duration: BG_MUSIC_TITLE_LOOP_DURATION_SEC,
        config: {
          loop: true,
          volume: BG_MUSIC_VOLUME,
        },
      });
    }

    if (this.bgMusic.isPlaying) {
      return;
    }

    if (titleLoop) {
      this.bgMusic.play(BG_MUSIC_TITLE_LOOP_MARKER);
    } else {
      this.bgMusic.play({ loop: true, volume: BG_MUSIC_VOLUME });
    }
  }

  /** Switch from the title-screen intro loop (0–22s) to looping the full track. */
  leaveTitleMusicLoop(): void {
    if (!this.bgMusic || !this.unlocked) {
      this.bgMusicTitleLoop = false;
      return;
    }

    let seek = 0;
    if (this.bgMusic.isPlaying) {
      seek = this.bgMusic.seek;
      if (this.bgMusicTitleLoop) {
        const marker = this.bgMusic.currentMarker;
        if (marker) {
          seek = (marker.start ?? 0) + seek;
        }
      }
      this.bgMusic.stop();
    }

    this.bgMusicTitleLoop = false;
    this.bgMusic.play({ loop: true, volume: BG_MUSIC_VOLUME, seek });
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
    this.bgMusic?.stop();
    this.bgMusic?.destroy();
    this.bgMusic = undefined;
  }
}
