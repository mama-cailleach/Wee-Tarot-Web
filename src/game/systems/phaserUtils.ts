import Phaser from "phaser";
import { GAME_HEIGHT, GAME_WIDTH } from "../config";
import { TAROTHEQUE_FONT, TAROTHEQUE_SIZE } from "./tarothequeFont";
import { wrapTextToWidth } from "./textWrap";

/** UI layer — above background art (Playdate uses setZIndex(200+) for similar UI). */
export const UI_DEPTH = 200;

export type UiText = Phaser.GameObjects.BitmapText;

export function initSceneCamera(scene: Phaser.Scene): void {
  scene.cameras.main.roundPixels = false;
}

/** Display an image at native size, shrinking only if it would overflow the 400×240 frame. */
export function fitImageToGameFrame(image?: Phaser.GameObjects.Image): void {
  if (!image) {
    return;
  }

  const source = image.texture?.getSourceImage() as { width?: number; height?: number } | undefined;
  const width = source?.width || image.frame?.realWidth || image.frame?.width || 0;
  const height = source?.height || image.frame?.realHeight || image.frame?.height || 0;
  if (width <= 0 || height <= 0 || !Number.isFinite(width) || !Number.isFinite(height)) {
    image.setScale(1);
    return;
  }

  const scale = Math.min(1, GAME_WIDTH / width, GAME_HEIGHT / height);
  image.setScale(Number.isFinite(scale) && scale > 0 ? scale : 1);
}

/**
 * Load a PNG after the scene has already started. Phaser's scene loader often
 * never emits COMPLETE for late `load.image()` calls, so this uses an HTML Image
 * and `textures.addImage` instead.
 */
export function loadTextureFromUrl(
  scene: Phaser.Scene,
  key: string,
  url: string,
  onReady: (key: string) => void,
): void {
  const existing = scene.textures.exists(key) ? scene.textures.get(key) : undefined;
  if (existing?.source[0]?.width) {
    onReady(key);
    return;
  }
  if (scene.textures.exists(key)) {
    scene.textures.remove(key);
  }

  const image = new Image();
  image.onload = () => {
    if (!scene.sys.displayList) {
      return;
    }
    if (!scene.textures.exists(key)) {
      scene.textures.addImage(key, image);
    }
    onReady(key);
  };
  image.onerror = () => {
    console.error(`[texture] failed to load "${key}" from ${url}`);
  };
  image.src = url;
}

type GameTextStyle = {
  fontSize?: number;
  color?: string;
  align?: "left" | "center" | "right";
  wordWrap?: { width: number };
};

const DEFAULT_TEXT_COLOR = 0xa9aaad;

function parseTint(color?: string): number {
  if (!color) {
    return DEFAULT_TEXT_COLOR;
  }
  if (color.startsWith("#")) {
    return Number.parseInt(color.slice(1), 16);
  }
  return DEFAULT_TEXT_COLOR;
}

function measureBitmapTextWidth(scene: Phaser.Scene, text: string, fontSize: number): number {
  const font = scene.cache.bitmapFont.get(TAROTHEQUE_FONT) as
    | { data?: { chars?: Record<number, { xAdvance?: number }>; size?: number } }
    | undefined;
  const chars = font?.data?.chars;
  const nativeSize = font?.data?.size ?? TAROTHEQUE_SIZE;
  if (!chars || nativeSize <= 0) {
    return 0;
  }

  const scale = fontSize / nativeSize;
  let width = 0;
  for (let index = 0; index < text.length; index += 1) {
    const glyph = chars[text.charCodeAt(index)];
    if (glyph) {
      width += glyph.xAdvance ?? 0;
    }
  }
  return width * scale;
}

export function addGameText(
  scene: Phaser.Scene,
  x: number,
  y: number,
  content: string,
  style: GameTextStyle = {},
): UiText {
  const size = style.fontSize ?? TAROTHEQUE_SIZE;
  const wrapped =
    style.wordWrap?.width != null
      ? wrapTextToWidth(content, style.wordWrap.width, (value) =>
          measureBitmapTextWidth(scene, value, size),
        )
      : content;
  const text = scene.add.bitmapText(
    Math.round(x),
    Math.round(y),
    TAROTHEQUE_FONT,
    wrapped,
    size,
  );

  text.setTint(parseTint(style.color));
  text.setDepth(UI_DEPTH);

  if (style.align === "center") {
    text.setCenterAlign();
  } else if (style.align === "right") {
    text.setRightAlign();
  } else {
    text.setLeftAlign();
  }

  return text;
}

export function registerGridFrames(
  scene: Phaser.Scene,
  textureKey: string,
  frameWidth: number,
  frameHeight: number,
): number {
  const texture = scene.textures.get(textureKey);
  const source = texture.getSourceImage() as HTMLImageElement | HTMLCanvasElement;
  const cols = Math.floor(source.width / frameWidth);
  const rows = Math.floor(source.height / frameHeight);

  if (texture.frameTotal === 1) {
    texture.remove("__BASE");
  }

  let frameIndex = 0;

  for (let row = 0; row < rows; row += 1) {
    for (let col = 0; col < cols; col += 1) {
      texture.add(frameIndex, 0, col * frameWidth, row * frameHeight, frameWidth, frameHeight);
      frameIndex += 1;
    }
  }

  return frameIndex;
}

export function loadSpritesheet(
  scene: Phaser.Scene,
  key: string,
  url: string,
  frameWidth: number,
  frameHeight: number,
): void {
  scene.load.spritesheet(key, url, { frameWidth, frameHeight });
}

export function playSpritesheetOnce(
  sprite: Phaser.GameObjects.Sprite,
  animKey: string,
  frameRate = 30,
  onComplete?: () => void,
  repeat = 0,
): void {
  if (!sprite.scene.anims.exists(animKey)) {
    sprite.scene.anims.create({
      key: animKey,
      frames: sprite.scene.anims.generateFrameNumbers(sprite.texture.key),
      frameRate,
      repeat: 0,
    });
  }

  sprite.once(Phaser.Animations.Events.ANIMATION_COMPLETE, () => {
    onComplete?.();
  });
  sprite.play({ key: animKey, frameRate, repeat });
}

export function createWrappedText(
  scene: Phaser.Scene,
  x: number,
  y: number,
  text: string,
  width: number,
  style?: GameTextStyle,
): UiText {
  return addGameText(scene, x, y, text, {
    align: "center",
    wordWrap: { width },
    ...style,
  }).setOrigin(0.5, 0.5);
}

/**
 * Registers an edge-triggered "confirm" action. Space, Enter, canvas tap, and
 * the HTML A button under the frame all fire the same shared input bus event.
 * Cleaned up automatically on scene shutdown.
 */
export { bindConfirm as onConfirm } from "./GameInput";
