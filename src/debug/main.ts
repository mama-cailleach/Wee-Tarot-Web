import Phaser from "phaser";
import { GAME_HEIGHT, GAME_WIDTH } from "../game/config";
import { bindNativeScale } from "../game/scale";
import { bindChromeControls } from "../game/systems/GameInput";
import { QaBootScene } from "./QaBootScene";
import { TextWrapQaScene } from "./TextWrapQaScene";

const parent = document.getElementById("game");
if (!parent) {
  throw new Error("Missing #game container");
}

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
    autoCenter: Phaser.Scale.NO_CENTER,
    width: GAME_WIDTH,
    height: GAME_HEIGHT,
  },
  scene: [QaBootScene, TextWrapQaScene],
});

bindNativeScale(game);
bindChromeControls(game);
