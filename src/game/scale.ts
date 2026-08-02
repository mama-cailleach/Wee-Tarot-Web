import Phaser from "phaser";
import { GAME_HEIGHT, GAME_WIDTH } from "./config";

const MAX_INTEGER_ZOOM = 4;

/** Vertical space reserved for the HTML chrome under the game frame. */
export function getChromeReservePx(): number {
  const chrome = document.getElementById("chrome");
  const stage = document.getElementById("stage");
  if (!chrome) {
    return 0;
  }

  const gap = stage ? Number.parseFloat(getComputedStyle(stage).gap || "0") || 0 : 0;
  return chrome.offsetHeight + gap;
}

export function getIntegerZoom(
  viewportWidth: number,
  viewportHeight: number,
): number {
  const zoomX = Math.floor(viewportWidth / GAME_WIDTH);
  const zoomY = Math.floor(viewportHeight / GAME_HEIGHT);
  return Math.max(1, Math.min(zoomX, zoomY, MAX_INTEGER_ZOOM));
}

export function applyIntegerScale(game: Phaser.Game): void {
  const app = document.getElementById("app");
  let viewportWidth = app?.clientWidth ?? 0;
  let viewportHeight = app?.clientHeight ?? 0;
  if (viewportWidth < 1 || viewportHeight < 1) {
    viewportWidth = window.innerWidth;
    viewportHeight = window.innerHeight;
  }

  // Leave room for the control chrome under the scaled canvas.
  const availableHeight = Math.max(GAME_HEIGHT, viewportHeight - getChromeReservePx());
  game.scale.setZoom(getIntegerZoom(viewportWidth, availableHeight));
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
