import Phaser from "phaser";
import { TAROTHEQUE_FONT, TAROTHEQUE_SIZE } from "./tarothequeFont";

/** UI layer — above background art (Playdate uses setZIndex(200+) for similar UI). */
export const UI_DEPTH = 200;

export type UiText = Phaser.GameObjects.BitmapText;

export function initSceneCamera(scene: Phaser.Scene): void {
  scene.cameras.main.roundPixels = false;
}

type GameTextStyle = {
  fontSize?: number;
  color?: string;
  align?: "left" | "center" | "right";
  wordWrap?: { width: number };
};

function parseTint(color?: string): number {
  if (!color) {
    return 0x000000;
  }
  if (color.startsWith("#")) {
    return Number.parseInt(color.slice(1), 16);
  }
  return 0x000000;
}

export function addGameText(
  scene: Phaser.Scene,
  x: number,
  y: number,
  content: string,
  style: GameTextStyle = {},
): UiText {
  const size = style.fontSize ?? TAROTHEQUE_SIZE;
  const text = scene.add.bitmapText(
    Math.round(x),
    Math.round(y),
    TAROTHEQUE_FONT,
    content,
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

  if (style.wordWrap?.width) {
    text.setMaxWidth(style.wordWrap.width);
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
  sprite.play(animKey);
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

export function confirmPressed(scene: Phaser.Scene): boolean {
  const space = scene.input.keyboard?.addKey(Phaser.Input.Keyboard.KeyCodes.SPACE);
  const enter = scene.input.keyboard?.addKey(Phaser.Input.Keyboard.KeyCodes.ENTER);
  const pointer = scene.input.activePointer;
  const tapped = pointer.isDown && pointer.getDuration() > 0 && pointer.getDuration() <= 50;
  return (
    (space !== undefined && Phaser.Input.Keyboard.JustDown(space)) ||
    (enter !== undefined && Phaser.Input.Keyboard.JustDown(enter)) ||
    tapped
  );
}
