import Phaser from "phaser";

/** Keep the canvas at native Playdate size (400×240). Never scale with the window. */
export function lockNativeScale(game: Phaser.Game): void {
  game.scale.setZoom(1);
  game.scale.refresh();
}

export function bindNativeScale(game: Phaser.Game): void {
  const lock = () => lockNativeScale(game);
  game.events.once(Phaser.Core.Events.READY, lock);
  window.addEventListener("resize", lock);
  game.events.once("destroy", () => {
    window.removeEventListener("resize", lock);
  });
}
