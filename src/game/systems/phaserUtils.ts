import Phaser from "phaser";

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
    texture.remove(0);
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
  style?: Phaser.Types.GameObjects.Text.TextStyle,
): Phaser.GameObjects.Text {
  return scene.add
    .text(x, y, text, {
      fontFamily: "Georgia, serif",
      fontSize: "14px",
      color: "#000000",
      align: "center",
      wordWrap: { width },
      ...style,
    })
    .setOrigin(0.5, 0.5);
}

export function confirmPressed(scene: Phaser.Scene): boolean {
  const space = scene.input.keyboard?.addKey(Phaser.Input.Keyboard.KeyCodes.SPACE);
  const enter = scene.input.keyboard?.addKey(Phaser.Input.Keyboard.KeyCodes.ENTER);
  return (
    (space !== undefined && Phaser.Input.Keyboard.JustDown(space)) ||
    (enter !== undefined && Phaser.Input.Keyboard.JustDown(enter)) ||
    scene.input.activePointer.justDown
  );
}
