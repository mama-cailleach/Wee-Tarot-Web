import Phaser from "phaser";
import { preloadSliceAssets } from "../preloadAssets";
import { SoundManager } from "../systems/SoundManager";

export class BootScene extends Phaser.Scene {
  constructor() {
    super({ key: "BootScene" });
  }

  preload(): void {
    this.load.on("loaderror", (file: Phaser.Loader.File) => {
      console.error("[BootScene] asset failed:", file.key, file.url);
    });
    this.load.once("complete", () => {
      console.log("[BootScene] preload complete");
    });

    preloadSliceAssets(this);
  }

  create(): void {
    console.log("[BootScene] create → starting LaunchScene");
    this.registry.set("sound", new SoundManager(this));
    this.cameras.main.setVisible(false);
    this.scene.start("LaunchScene");
  }
}
