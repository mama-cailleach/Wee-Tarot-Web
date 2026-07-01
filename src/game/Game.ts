import Phaser from "phaser";
import { GAME_HEIGHT, GAME_WIDTH } from "./config";
import { BootScene } from "./scenes/BootScene";
import { OneCardGameScene } from "./scenes/OneCardGameScene";
import { OneCardPostScene } from "./scenes/OneCardPostScene";
import { TitleScene } from "./scenes/TitleScene";
import { bindIntegerScale } from "./scale";

export function createGame(parent: string | HTMLElement): Phaser.Game {
  const game = new Phaser.Game({
    type: Phaser.AUTO,
    parent,
    width: GAME_WIDTH,
    height: GAME_HEIGHT,
    backgroundColor: "#1a1a1a",
    pixelArt: true,
    antialias: false,
    roundPixels: false,
    scale: {
      mode: Phaser.Scale.NONE,
      autoCenter: Phaser.Scale.CENTER_BOTH,
      width: GAME_WIDTH,
      height: GAME_HEIGHT,
    },
    scene: [BootScene, OneCardGameScene, TitleScene, OneCardPostScene],
    audio: {
      disableWebAudio: false,
    },
  });

  bindIntegerScale(game);
  return game;
}
