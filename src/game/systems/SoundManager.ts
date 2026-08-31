import Phaser from "phaser";

const BG_MUSIC_KEY = "music-bg";
const RAIN_KEY = "music-rain";
const BG_MUSIC_VOLUME = 0.9;
const DEFAULT_AMBIENCE_VOLUME = 0.1;
const A_BUT_VOLUME = 0.5;
const A_BUT_VARIANT_COUNT = 10;
const BG_MUSIC_TITLE_LOOP_MARKER = "title-loop";
const BG_MUSIC_TITLE_LOOP_DURATION_SEC = 22;

const STORAGE_SOUND_MODE = "weeTarot.soundMode";
const STORAGE_SFX_ENABLED = "weeTarot.sfxEnabled";
const STORAGE_MUTED = "weeTarot.muted";

/** 1 = Music&Rain, 2 = Music, 3 = Rain */
export type SoundMode = 1 | 2 | 3;

function clampSoundMode(mode: unknown): SoundMode {
  const numeric = Number(mode);
  if (numeric === 1 || numeric === 2 || numeric === 3) {
    return numeric;
  }
  return 1;
}

function readStoredSoundMode(): SoundMode {
  try {
    return clampSoundMode(localStorage.getItem(STORAGE_SOUND_MODE));
  } catch {
    return 1;
  }
}

function readStoredSfxEnabled(): boolean {
  try {
    const value = localStorage.getItem(STORAGE_SFX_ENABLED);
    if (value === null) {
      return true;
    }
    return value !== "false";
  } catch {
    return true;
  }
}

export function readStoredMuted(): boolean {
  try {
    return localStorage.getItem(STORAGE_MUTED) === "true";
  } catch {
    return false;
  }
}

export function writeStoredMuted(muted: boolean): void {
  try {
    localStorage.setItem(STORAGE_MUTED, muted ? "true" : "false");
  } catch {
    // Ignore quota / private-mode failures.
  }
}

export class SoundManager {
  private unlocked = false;
  private crankSound?: Phaser.Sound.BaseSound;
  private bgMusic?: Phaser.Sound.WebAudioSound;
  private rain?: Phaser.Sound.WebAudioSound;
  private bgMusicTitleLoop = false;
  private soundMode: SoundMode = 1;
  private sfxEnabled = true;
  private muted = false;
  private ambienceVolume = DEFAULT_AMBIENCE_VOLUME;

  constructor(private readonly scene: Phaser.Scene) {
    this.soundMode = readStoredSoundMode();
    this.sfxEnabled = readStoredSfxEnabled();
    this.muted = readStoredMuted();
    this.applyMute();
  }

  unlock(): void {
    if (this.unlocked) {
      return;
    }

    if (this.scene.sound.locked) {
      this.scene.sound.unlock();
    }
    this.unlocked = true;
    this.applyMute();
    this.startBgMusic(this.bgMusicTitleLoop);
    this.applySoundMode();
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

    if (!this.bgMusic.isPlaying) {
      if (titleLoop) {
        this.bgMusic.play(BG_MUSIC_TITLE_LOOP_MARKER);
      } else {
        this.bgMusic.play({ loop: true, volume: BG_MUSIC_VOLUME });
      }
    }

    this.applySoundMode();
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
    this.applySoundMode();
  }

  playSfx(key: string, config?: Phaser.Types.Sound.SoundConfig): void {
    if (!this.unlocked || !this.sfxEnabled || this.muted) {
      return;
    }
    if (this.scene.cache.audio.exists(key)) {
      this.scene.sound.play(key, config);
    }
  }

  /** Random A-button click among a_but1–a_but10 (Playdate Sound.playABut). */
  playABut(): void {
    if (!this.unlocked || !this.sfxEnabled || this.muted) {
      return;
    }
    const variant = Math.floor(Math.random() * A_BUT_VARIANT_COUNT) + 1;
    const key = `sfx-a-but-${variant}`;
    if (this.scene.cache.audio.exists(key)) {
      this.scene.sound.play(key, { volume: A_BUT_VOLUME });
    }
  }

  getSoundMode(): SoundMode {
    return this.soundMode;
  }

  setSoundMode(mode: SoundMode): SoundMode {
    this.soundMode = clampSoundMode(mode);
    try {
      localStorage.setItem(STORAGE_SOUND_MODE, String(this.soundMode));
    } catch {
      // Ignore quota / private-mode failures.
    }
    this.applySoundMode();
    return this.soundMode;
  }

  getSfxEnabled(): boolean {
    return this.sfxEnabled;
  }

  setSfxEnabled(enabled: boolean): boolean {
    this.sfxEnabled = enabled;
    try {
      localStorage.setItem(STORAGE_SFX_ENABLED, String(this.sfxEnabled));
    } catch {
      // Ignore quota / private-mode failures.
    }
    return this.sfxEnabled;
  }

  isMuted(): boolean {
    return this.muted;
  }

  setMuted(muted: boolean): boolean {
    this.muted = muted;
    writeStoredMuted(muted);
    this.applyMute();
    if (!this.muted && this.unlocked) {
      this.applySoundMode();
    }
    return this.muted;
  }

  setAmbienceVolume(volume: number): void {
    this.ambienceVolume = Math.max(0, Math.min(1, volume));
    if (this.rain) {
      this.rain.setVolume(this.ambienceVolume);
    }
  }

  playAmbience(): boolean {
    if (!this.unlocked || this.soundMode === 2 || this.muted) {
      if (this.soundMode === 2) {
        this.stopAmbience();
      }
      return false;
    }
    if (!this.scene.cache.audio.exists(RAIN_KEY)) {
      return false;
    }

    if (!this.rain) {
      this.rain = this.scene.sound.add(RAIN_KEY, {
        loop: true,
        volume: this.ambienceVolume,
      }) as Phaser.Sound.WebAudioSound;
    }

    if (!this.rain.isPlaying) {
      this.rain.play();
    }
    this.rain.setVolume(this.ambienceVolume);
    return true;
  }

  stopAmbience(): boolean {
    if (!this.rain) {
      return false;
    }
    if (this.rain.isPlaying) {
      this.rain.stop();
    }
    return true;
  }

  private applySoundMode(): void {
    if (!this.unlocked) {
      return;
    }

    if (this.soundMode === 1) {
      this.bgMusic?.setVolume(BG_MUSIC_VOLUME);
      this.playAmbience();
    } else if (this.soundMode === 2) {
      this.bgMusic?.setVolume(BG_MUSIC_VOLUME);
      this.stopAmbience();
    } else {
      this.bgMusic?.setVolume(0);
      this.playAmbience();
    }
  }

  private applyMute(): void {
    this.scene.sound.mute = this.muted;
  }

  startCrankLoop(): void {
    if (
      !this.unlocked ||
      !this.sfxEnabled ||
      this.muted ||
      !this.scene.cache.audio.exists("sfx-crank")
    ) {
      return;
    }

    if (!this.crankSound) {
      this.crankSound = this.scene.sound.add("sfx-crank", { loop: false, volume: 0.65 });
    }

    if (this.crankSound.isPlaying) {
      this.crankSound.stop();
    }
    this.crankSound.play();
  }

  stopCrankLoop(): void {
    this.crankSound?.stop();
    this.crankSound?.destroy();
    this.crankSound = undefined;
  }

  destroy(): void {
    this.stopCrankLoop();
    this.stopAmbience();
    this.rain?.destroy();
    this.rain = undefined;
    this.bgMusic?.stop();
    this.bgMusic?.destroy();
    this.bgMusic = undefined;
  }
}
