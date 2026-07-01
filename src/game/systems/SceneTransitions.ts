import Phaser from "phaser";
import { SCENE_FADE_MS } from "../config";

export function switchScene(
  scene: Phaser.Scene,
  key: string,
  data?: object,
): void {
  if (scene.registry.get("sceneTransitioning")) {
    return;
  }

  scene.registry.set("sceneTransitioning", true);
  const { width, height } = scene.scale;
  const overlay = scene.add
    .rectangle(width / 2, height / 2, width, height, 0x000000, 0)
    .setDepth(10_000)
    .setScrollFactor(0);

  scene.tweens.add({
    targets: overlay,
    alpha: 1,
    duration: SCENE_FADE_MS,
    ease: "Cubic.easeInOut",
    onComplete: () => {
      overlay.destroy();
      scene.scene.start(key, { ...data, __fadeIn: true });
    },
  });
}

export function fadeInIfNeeded(scene: Phaser.Scene): void {
  const data = scene.scene.settings.data as { __fadeIn?: boolean };
  if (!data?.__fadeIn) {
    return;
  }

  const { width, height } = scene.scale;
  const overlay = scene.add
    .rectangle(width / 2, height / 2, width, height, 0x000000, 1)
    .setDepth(10_000)
    .setScrollFactor(0);

  scene.tweens.add({
    targets: overlay,
    alpha: 0,
    duration: SCENE_FADE_MS,
    ease: "Cubic.easeInOut",
    onComplete: () => {
      overlay.destroy();
      scene.registry.set("sceneTransitioning", false);
    },
  });
}
