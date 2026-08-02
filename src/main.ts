import { createGame } from "./game/Game";
import { bindChromeControls } from "./game/systems/GameInput";

const parent = document.getElementById("game");
if (!parent) {
  throw new Error("Missing #game container");
}

const game = createGame(parent);
bindChromeControls(game);
