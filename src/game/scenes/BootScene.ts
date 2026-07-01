import Phaser from "phaser";
import { parseSpritesheetMeta, SLICE_ASSETS } from "../config";
import { loadSpritesheet } from "../systems/phaserUtils";
import { SoundManager } from "../systems/SoundManager";

function sheet(
  scene: Phaser.Scene,
  key: string,
  url: string,
): void {
  const meta = parseSpritesheetMeta(url);
  if (!meta) {
    scene.load.image(key, url);
    return;
  }
  loadSpritesheet(scene, key, url, meta.frameWidth, meta.frameHeight);
}

export class BootScene extends Phaser.Scene {
  constructor() {
    super({ key: "BootScene" });
  }

  preload(): void {
    this.load.image("launch", SLICE_ASSETS.images.launchImage);
    this.load.image("title-anim-sheet", SLICE_ASSETS.images.titleAnim);
    this.load.image("playspace", SLICE_ASSETS.images.tarotPlayspace);
    this.load.image("darkcloth", SLICE_ASSETS.images.darkcloth);
    sheet(this, "dinah-bg", SLICE_ASSETS.images.dinahBg);
    this.load.image("placement-diamond", SLICE_ASSETS.images.placementDiamond);
    this.load.image("scroll-box", SLICE_ASSETS.images.scrollBox);
    this.load.image("icon-tri", SLICE_ASSETS.images.iconTri);

    sheet(this, "shuffle", SLICE_ASSETS.images.shuffle);
    sheet(this, "spin-slide", SLICE_ASSETS.images.cardSpinSlide);
    sheet(this, "deck-laying", SLICE_ASSETS.images.deckLaying);
    sheet(this, "explode-finale", SLICE_ASSETS.images.explodeFinale);
    sheet(this, "reveal", SLICE_ASSETS.images.reveal);

    this.load.audio("sfx-cards-slow", SLICE_ASSETS.audio.cardsSlow);
    this.load.audio("sfx-cards-fast", SLICE_ASSETS.audio.cardsFast);
    this.load.audio("sfx-crank", SLICE_ASSETS.audio.crank);
    this.load.audio("sfx-tuin", SLICE_ASSETS.audio.tuin);
    this.load.audio("sfx-a-but", SLICE_ASSETS.audio.aBut);
    this.load.audio("music-bg", SLICE_ASSETS.audio.bgMusic);
  }

  create(): void {
    this.registry.set("sound", new SoundManager(this));
    this.registry.set("sceneTransitioning", false);
    this.scene.start("TitleScene");
  }
}
