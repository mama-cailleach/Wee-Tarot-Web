import Phaser from "phaser";
import { GAME_HEIGHT, GAME_WIDTH } from "./config";
import { BootScene } from "./scenes/BootScene";
import { CardReviewScene } from "./scenes/CardReviewScene";
import { HowToScene } from "./scenes/HowToScene";
import { LaunchScene } from "./scenes/LaunchScene";
import { MenuScene } from "./scenes/MenuScene";
import { OneCardGameScene } from "./scenes/OneCardGameScene";
import { OneCardPostScene } from "./scenes/OneCardPostScene";
import { SettingsScene } from "./scenes/SettingsScene";
import { SoundSettingsScene } from "./scenes/SoundSettingsScene";
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
      // Centering is handled by the #game flexbox in index.html. Letting Phaser
      // also autoCenter injects canvas margins that fight the flexbox and push
      // the canvas off to one side.
      autoCenter: Phaser.Scale.NO_CENTER,
      width: GAME_WIDTH,
      height: GAME_HEIGHT,
    },
    scene: [
      BootScene,
      LaunchScene,
      OneCardGameScene,
      TitleScene,
      MenuScene,
      SettingsScene,
      SoundSettingsScene,
      HowToScene,
      OneCardPostScene,
      CardReviewScene,
    ],
    audio: {
      disableWebAudio: false,
    },
  });

  bindIntegerScale(game);
  return game;
}
