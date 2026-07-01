import { createGame } from "./game/Game";

const parent = document.getElementById("game");
if (!parent) {
  throw new Error("Missing #game container");
}

createGame(parent);
