import Phaser from "phaser";
import { GAME_HEIGHT, GAME_WIDTH } from "./config";

const MAX_INTEGER_ZOOM = 4;

export function getIntegerZoom(
  viewportWidth: number,
  viewportHeight: number,
): number {
  const zoomX = Math.floor(viewportWidth / GAME_WIDTH);
  const zoomY = Math.floor(viewportHeight / GAME_HEIGHT);
  return Math.max(1, Math.min(zoomX, zoomY, MAX_INTEGER_ZOOM));
}

export function applyIntegerScale(game: Phaser.Game): void {
  const parent = game.scale.parent;
  let viewportWidth = parent?.clientWidth ?? 0;
  let viewportHeight = parent?.clientHeight ?? 0;
  if (viewportWidth < 1 || viewportHeight < 1) {
    viewportWidth = window.innerWidth;
    viewportHeight = window.innerHeight;
  }
  game.scale.setZoom(getIntegerZoom(viewportWidth, viewportHeight));
  game.scale.refresh();
}

export function bindIntegerScale(game: Phaser.Game): void {
  const refresh = () => applyIntegerScale(game);
  game.events.once(Phaser.Core.Events.READY, refresh);
  window.addEventListener("resize", refresh);
  game.events.once("destroy", () => {
    window.removeEventListener("resize", refresh);
  });
}
