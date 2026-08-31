import Phaser from "phaser";
import { preloadSliceAssets } from "../game/preloadAssets";

export class QaBootScene extends Phaser.Scene {
  constructor() {
    super({ key: "QaBootScene" });
  }

  preload(): void {
    preloadSliceAssets(this);
  }

  create(): void {
    this.scene.start("TextWrapQaScene");
  }
}
