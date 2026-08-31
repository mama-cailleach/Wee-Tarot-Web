import Phaser from "phaser";
import { SCENE_FADE_MS } from "../config";

const TEXTURE_KEY = "dinah-bg";
const IDLE_ANIM_KEY = "dinah-idle";
const IDLE_FRAMES = 6;
const IDLE_FRAME_RATE = 8;
const LEAVE_FRAME_RATE = 30;

function ensureIdleAnim(scene: Phaser.Scene): void {
  if (scene.anims.exists(IDLE_ANIM_KEY)) {
    return;
  }

  const frameTotal = scene.textures.get(TEXTURE_KEY).frameTotal;
  scene.anims.create({
    key: IDLE_ANIM_KEY,
    frames: scene.anims.generateFrameNumbers(TEXTURE_KEY, {
      start: 0,
      end: Math.min(IDLE_FRAMES - 1, frameTotal - 1),
    }),
    frameRate: IDLE_FRAME_RATE,
    yoyo: true,
    repeat: -1,
  });
}

function ensureLeaveAnim(scene: Phaser.Scene, endFrame: number): string {
  const key = `dinah-leave-${endFrame}`;
  if (scene.anims.exists(key)) {
    return key;
  }

  const frameTotal = scene.textures.get(TEXTURE_KEY).frameTotal;
  scene.anims.create({
    key,
    frames: scene.anims.generateFrameNumbers(TEXTURE_KEY, {
      start: 0,
      end: Math.min(endFrame, frameTotal - 1),
    }),
    frameRate: LEAVE_FRAME_RATE,
    repeat: 0,
  });
  return key;
}

export function createDinahSprite(scene: Phaser.Scene): Phaser.GameObjects.Sprite {
  ensureIdleAnim(scene);
  const sprite = scene.add.sprite(200, 120, TEXTURE_KEY, 0).setDepth(0).setAlpha(0.9);
  sprite.play(IDLE_ANIM_KEY);
  return sprite;
}

/** Playdate menu leave uses frames 1–17 (Phaser 0–16). */
export const DINAH_LEAVE_MENU_END = 16;
/** Playdate post leave is defined as frames 1–20 (Phaser 0–19). */
export const DINAH_LEAVE_POST_END = 19;

export function playDinahLeave(
  scene: Phaser.Scene,
  sprite: Phaser.GameObjects.Sprite,
  endFrame: number,
  onComplete: () => void,
): void {
  const key = ensureLeaveAnim(scene, endFrame);
  sprite.once(Phaser.Animations.Events.ANIMATION_COMPLETE, () => {
    scene.cameras.main.fadeOut(SCENE_FADE_MS, 0, 0, 0);
    scene.cameras.main.once(Phaser.Cameras.Scene2D.Events.FADE_OUT_COMPLETE, onComplete);
  });
  sprite.play(key);
}
