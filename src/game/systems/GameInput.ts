import Phaser from "phaser";

export const INPUT_CONFIRM = "input:confirm";
export const INPUT_AUTO_SHUFFLE = "input:autoShuffle";

export type ChromeActions = {
  confirm: boolean;
  shuffle: boolean;
};

function chromeButtons(): {
  confirm: HTMLButtonElement | null;
  shuffle: HTMLButtonElement | null;
} {
  return {
    confirm: document.getElementById("btn-a") as HTMLButtonElement | null,
    shuffle: document.getElementById("btn-shuffle") as HTMLButtonElement | null,
  };
}

/** Enable/disable the HTML chrome buttons under the game frame. */
export function setChromeActions(actions: Partial<ChromeActions>): void {
  const buttons = chromeButtons();
  if (actions.confirm !== undefined && buttons.confirm) {
    buttons.confirm.disabled = !actions.confirm;
  }
  if (actions.shuffle !== undefined && buttons.shuffle) {
    buttons.shuffle.disabled = !actions.shuffle;
  }
}

export function emitConfirm(game: Phaser.Game): void {
  game.events.emit(INPUT_CONFIRM);
}

export function emitAutoShuffle(game: Phaser.Game): void {
  game.events.emit(INPUT_AUTO_SHUFFLE);
}

function refocusCanvas(game: Phaser.Game): void {
  const canvas = game.canvas;
  if (canvas && typeof canvas.focus === "function") {
    canvas.setAttribute("tabindex", "0");
    canvas.focus({ preventScroll: true });
  }
}

/**
 * Wire HTML A / Shuffle buttons to the shared input bus. Call once after the
 * Phaser game is created.
 */
export function bindChromeControls(game: Phaser.Game): void {
  const buttons = chromeButtons();

  const bindPress = (button: HTMLButtonElement | null, emit: () => void): void => {
    if (!button) {
      return;
    }

    const onPress = (event: Event) => {
      event.preventDefault();
      if (button.disabled) {
        return;
      }
      emit();
      refocusCanvas(game);
    };

    button.addEventListener("pointerdown", onPress);
  };

  bindPress(buttons.confirm, () => emitConfirm(game));
  bindPress(buttons.shuffle, () => emitAutoShuffle(game));

  setChromeActions({ confirm: false, shuffle: false });
}

/**
 * Register a confirm handler for the active scene. Keyboard (Space/Enter),
 * canvas tap, and the HTML A button all route through the same bus event.
 * Cleaned up automatically on scene shutdown.
 */
export function bindConfirm(scene: Phaser.Scene, handler: () => void): void {
  const game = scene.game;
  const onBus = () => handler();

  game.events.on(INPUT_CONFIRM, onBus);

  const emit = () => emitConfirm(game);
  scene.input.keyboard?.on("keydown-SPACE", emit);
  scene.input.keyboard?.on("keydown-ENTER", emit);
  scene.input.on(Phaser.Input.Events.POINTER_DOWN, emit);

  scene.events.once(Phaser.Scenes.Events.SHUTDOWN, () => {
    game.events.off(INPUT_CONFIRM, onBus);
    scene.input.keyboard?.off("keydown-SPACE", emit);
    scene.input.keyboard?.off("keydown-ENTER", emit);
    scene.input.off(Phaser.Input.Events.POINTER_DOWN, emit);
  });
}

/**
 * Register an auto-shuffle handler for the active scene (HTML Shuffle button).
 * Cleaned up automatically on scene shutdown.
 */
export function bindAutoShuffle(scene: Phaser.Scene, handler: () => void): void {
  const game = scene.game;
  const onBus = () => handler();

  game.events.on(INPUT_AUTO_SHUFFLE, onBus);

  scene.events.once(Phaser.Scenes.Events.SHUTDOWN, () => {
    game.events.off(INPUT_AUTO_SHUFFLE, onBus);
  });
}
