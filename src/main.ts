import { createGame } from "./game/Game";
import { bindChromeControls, bindMuteToggle } from "./game/systems/GameInput";

const parent = document.getElementById("game");
if (!parent) {
  throw new Error("Missing #game container");
}

const game = createGame(parent);
bindChromeControls(game);
bindMuteToggle(game);
