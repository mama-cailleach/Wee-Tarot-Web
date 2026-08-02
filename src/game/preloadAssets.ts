import Phaser from "phaser";
import { parseSpritesheetMeta, SLICE_ASSETS } from "./config";
import { loadTarothequeFont } from "./systems/tarothequeFont";
import { loadSpritesheet } from "./systems/phaserUtils";

function sheet(scene: Phaser.Scene, key: string, url: string): void {
  const meta = parseSpritesheetMeta(url);
  if (!meta) {
    scene.load.image(key, url);
    return;
  }
  loadSpritesheet(scene, key, url, meta.frameWidth, meta.frameHeight);
}

/** Preload assets used by the vertical slice. Call from a scene's preload(). */
export function preloadSliceAssets(scene: Phaser.Scene): void {
  loadTarothequeFont(scene);

  scene.load.image("launch", SLICE_ASSETS.images.launchImage);
  scene.load.image("launch-prompt", SLICE_ASSETS.images.launchImage2);
  sheet(scene, "title-anim-sheet", SLICE_ASSETS.images.titleAnim);
  scene.load.image("playspace", SLICE_ASSETS.images.tarotPlayspace);
  scene.load.image("darkcloth", SLICE_ASSETS.images.darkcloth);
  scene.load.image("icon-tri-smol", SLICE_ASSETS.images.iconTriSmol);
  sheet(scene, "dinah-bg", SLICE_ASSETS.images.dinahBg);
  scene.load.image("placement-diamond", SLICE_ASSETS.images.placementDiamond);
  scene.load.image("scroll-box", SLICE_ASSETS.images.scrollBox);

  sheet(scene, "shuffle", SLICE_ASSETS.images.shuffle);
  sheet(scene, "spin-slide", SLICE_ASSETS.images.cardSpinSlide);
  sheet(scene, "deck-laying", SLICE_ASSETS.images.deckLaying);
  sheet(scene, "explode-deck", SLICE_ASSETS.images.explodeDeck);
  sheet(scene, "scaled-card", SLICE_ASSETS.images.scaledCard);
  sheet(scene, "explode-finale", SLICE_ASSETS.images.explodeFinale);
  sheet(scene, "reveal", SLICE_ASSETS.images.reveal);

  scene.load.audio("sfx-cards-slow", SLICE_ASSETS.audio.cardsSlow);
  scene.load.audio("sfx-cards-fast", SLICE_ASSETS.audio.cardsFast);
  scene.load.audio("sfx-crank", SLICE_ASSETS.audio.crank);
  scene.load.audio("sfx-tuin", SLICE_ASSETS.audio.tuin);
  scene.load.audio("sfx-a-but", SLICE_ASSETS.audio.aBut);
  scene.load.audio("sfx-b-button", SLICE_ASSETS.audio.bButton);
  scene.load.audio("sfx-hahahaha", SLICE_ASSETS.audio.hahahaha);
  scene.load.audio("music-bg", SLICE_ASSETS.audio.bgMusic);
  scene.load.audio("title-start", SLICE_ASSETS.audio.titleStart);
}
