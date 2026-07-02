import Phaser from "phaser";
import { assetUrl } from "../config";

export const TAROTHEQUE_FONT = "tarotheque";
export const TAROTHEQUE_SIZE = 20;

export const TAROTHEQUE_ASSETS = {
  atlas: assetUrl("fonts", "tarotheque-v1-20-atlas.png"),
  xml: assetUrl("fonts", "tarotheque-v1-20.xml"),
} as const;

export function loadTarothequeFont(scene: Phaser.Scene): void {
  scene.load.bitmapFont(TAROTHEQUE_FONT, TAROTHEQUE_ASSETS.atlas, TAROTHEQUE_ASSETS.xml);
}
