import Phaser from "phaser";

export const INPUT_CONFIRM = "input:confirm";
export const INPUT_AUTO_SHUFFLE = "input:autoShuffle";
export const INPUT_ZOOM = "input:zoom";
export const INPUT_BACK = "input:back";
export const INPUT_UP = "input:up";
export const INPUT_DOWN = "input:down";

export type ChromeActions = {
  confirm: boolean;
  shuffle: boolean;
  zoom: boolean;
  back: boolean;
  /** Show Up/Down chrome pair (settings-only); hides middle button. */
  navigate: boolean;
  /** Middle button labeled Start; emits confirm (Launch/Title). */
  start: boolean;
};

function chromeButtons(): {
  confirm: HTMLButtonElement | null;
  middle: HTMLButtonElement | null;
  back: HTMLButtonElement | null;
  up: HTMLButtonElement | null;
  down: HTMLButtonElement | null;
  nav: HTMLElement | null;
} {
  return {
    confirm: document.getElementById("btn-confirm") as HTMLButtonElement | null,
    middle: document.getElementById("btn-middle") as HTMLButtonElement | null,
    back: document.getElementById("btn-back") as HTMLButtonElement | null,
    up: document.getElementById("btn-up") as HTMLButtonElement | null,
    down: document.getElementById("btn-down") as HTMLButtonElement | null,
    nav: document.getElementById("chrome-nav"),
  };
}

type MiddleMode = "none" | "shuffle" | "zoom" | "start";

let middleMode: MiddleMode = "none";
let navigateVisible = false;

function applyMiddleMode(mode: MiddleMode): void {
  middleMode = mode;
  const middle = chromeButtons().middle;
  if (!middle || navigateVisible) {
    return;
  }

  if (mode === "shuffle") {
    middle.textContent = "Shuffle";
    middle.disabled = false;
    middle.classList.remove("is-hidden");
  } else if (mode === "zoom") {
    middle.textContent = "Zoom";
    middle.disabled = false;
    middle.classList.remove("is-hidden");
  } else if (mode === "start") {
    middle.textContent = "Start";
    middle.disabled = false;
    middle.classList.remove("is-hidden");
  } else {
    middle.disabled = true;
    middle.classList.add("is-hidden");
  }
}

function applyNavigateVisible(visible: boolean): void {
  navigateVisible = visible;
  const buttons = chromeButtons();

  if (buttons.nav) {
    buttons.nav.classList.toggle("is-visible", visible);
  }
  if (buttons.middle) {
    buttons.middle.classList.toggle("is-hidden", visible);
  }
  if (buttons.up) {
    buttons.up.disabled = !visible;
  }
  if (buttons.down) {
    buttons.down.disabled = !visible;
  }

  if (!visible) {
    applyMiddleMode(middleMode);
  }
}

/** Enable/disable the HTML chrome buttons under the game frame. */
export function setChromeActions(actions: Partial<ChromeActions>): void {
  const buttons = chromeButtons();

  if (actions.confirm !== undefined && buttons.confirm) {
    buttons.confirm.disabled = !actions.confirm;
  }

  if (actions.back !== undefined && buttons.back) {
    buttons.back.disabled = !actions.back;
  }

  if (actions.navigate !== undefined) {
    applyNavigateVisible(actions.navigate);
  }

  const nextShuffle = actions.shuffle ?? false;
  const nextZoom = actions.zoom ?? false;
  const nextStart = actions.start ?? false;

  if (
    actions.shuffle !== undefined ||
    actions.zoom !== undefined ||
    actions.start !== undefined
  ) {
    if (nextZoom) {
      applyMiddleMode("zoom");
    } else if (nextShuffle) {
      applyMiddleMode("shuffle");
    } else if (nextStart) {
      applyMiddleMode("start");
    } else {
      applyMiddleMode("none");
    }
  }
}

export function emitConfirm(game: Phaser.Game): void {
  game.events.emit(INPUT_CONFIRM);
}

export function emitAutoShuffle(game: Phaser.Game): void {
  game.events.emit(INPUT_AUTO_SHUFFLE);
}

export function emitZoom(game: Phaser.Game): void {
  game.events.emit(INPUT_ZOOM);
}

export function emitBack(game: Phaser.Game): void {
  game.events.emit(INPUT_BACK);
}

export function emitUp(game: Phaser.Game): void {
  game.events.emit(INPUT_UP);
}

export function emitDown(game: Phaser.Game): void {
  game.events.emit(INPUT_DOWN);
}

function refocusCanvas(game: Phaser.Game): void {
  const canvas = game.canvas;
  if (canvas && typeof canvas.focus === "function") {
    canvas.setAttribute("tabindex", "0");
    canvas.focus({ preventScroll: true });
  }
}

/**
 * Wire HTML chrome buttons to the shared input bus. Call once after the
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
  bindPress(buttons.back, () => emitBack(game));
  bindPress(buttons.up, () => emitUp(game));
  bindPress(buttons.down, () => emitDown(game));
  bindPress(buttons.middle, () => {
    if (middleMode === "shuffle") {
      emitAutoShuffle(game);
    } else if (middleMode === "zoom") {
      emitZoom(game);
    } else if (middleMode === "start") {
      emitConfirm(game);
    }
  });

  setChromeActions({
    confirm: false,
    shuffle: false,
    zoom: false,
    back: false,
    navigate: false,
    start: false,
  });
}

/**
 * Register a confirm handler for the active scene. Keyboard (Space/Enter),
 * canvas tap, and the HTML > button all route through the same bus event.
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
 * Register an auto-shuffle handler for the active scene (middle Shuffle button).
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

/**
 * Register a zoom-toggle handler for the active scene (middle Zoom button).
 * Cleaned up automatically on scene shutdown.
 */
export function bindZoom(scene: Phaser.Scene, handler: () => void): void {
  const game = scene.game;
  const onBus = () => handler();

  game.events.on(INPUT_ZOOM, onBus);

  scene.events.once(Phaser.Scenes.Events.SHUTDOWN, () => {
    game.events.off(INPUT_ZOOM, onBus);
  });
}

/**
 * Register a back handler for the active scene (HTML < button).
 * Cleaned up automatically on scene shutdown.
 */
export function bindBack(scene: Phaser.Scene, handler: () => void): void {
  const game = scene.game;
  const onBus = () => handler();

  game.events.on(INPUT_BACK, onBus);

  scene.events.once(Phaser.Scenes.Events.SHUTDOWN, () => {
    game.events.off(INPUT_BACK, onBus);
  });
}

/**
 * Register an up-navigate handler (chrome ▲ + keyboard Up).
 * Cleaned up automatically on scene shutdown.
 */
export function bindUp(scene: Phaser.Scene, handler: () => void): void {
  const game = scene.game;
  const onBus = () => handler();
  const onKey = () => emitUp(game);

  game.events.on(INPUT_UP, onBus);
  scene.input.keyboard?.on("keydown-UP", onKey);

  scene.events.once(Phaser.Scenes.Events.SHUTDOWN, () => {
    game.events.off(INPUT_UP, onBus);
    scene.input.keyboard?.off("keydown-UP", onKey);
  });
}

/**
 * Register a down-navigate handler (chrome ▼ + keyboard Down).
 * Cleaned up automatically on scene shutdown.
 */
export function bindDown(scene: Phaser.Scene, handler: () => void): void {
  const game = scene.game;
  const onBus = () => handler();
  const onKey = () => emitDown(game);

  game.events.on(INPUT_DOWN, onBus);
  scene.input.keyboard?.on("keydown-DOWN", onKey);

  scene.events.once(Phaser.Scenes.Events.SHUTDOWN, () => {
    game.events.off(INPUT_DOWN, onBus);
    scene.input.keyboard?.off("keydown-DOWN", onKey);
  });
}
