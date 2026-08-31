import Phaser from "phaser";
import {
  bindBack,
  bindDown,
  bindUp,
  setChromeActions,
} from "../systems/GameInput";
import {
  deckModeLabel,
  getDeckMode,
  setDeckMode,
  toggleDeckMode,
} from "../systems/deckMode";
import type { SoundManager } from "../systems/SoundManager";
import {
  addGameText,
  initSceneCamera,
  onConfirm,
  type UiText,
} from "../systems/phaserUtils";

const BUTTON_X = 200;
const TOP_Y = 70;
const STEP = 35;
const BACK_Y = 212;
const SELECTOR_X = 200;
const SELECTOR_OFFSET = 18;

type SettingsOptionKey = "how_to" | "sound" | "deck" | "hahahaha" | "back";

type SettingsOption = {
  text: string;
  y: number;
  key: SettingsOptionKey;
};

export class SettingsScene extends Phaser.Scene {
  private selectedIndex = 0;
  private selector?: Phaser.GameObjects.Image;
  private optionLabels: UiText[] = [];
  private options: SettingsOption[] = [];

  constructor() {
    super({ key: "SettingsScene" });
  }

  create(): void {
    initSceneCamera(this);

    this.selectedIndex = 0;
    this.optionLabels = [];
    this.options = [
      { text: "How To", y: TOP_Y, key: "how_to" },
      { text: "Sounds", y: TOP_Y + STEP, key: "sound" },
      {
        text: deckModeLabel(getDeckMode(this.registry)),
        y: TOP_Y + 2 * STEP,
        key: "deck",
      },
      { text: "haha", y: TOP_Y + 3 * STEP, key: "hahahaha" },
      { text: "Back", y: BACK_Y, key: "back" },
    ];

    this.add.image(200, 120, "darkcloth").setDepth(0);

    addGameText(this, 200, 30, "MENU", {
      fontSize: 20,
      align: "center",
    }).setOrigin(0.5, 0.5);

    for (const option of this.options) {
      const label = addGameText(this, BUTTON_X, option.y, option.text, {
        fontSize: 20,
        align: "center",
      }).setOrigin(0.5, 0.5);
      this.optionLabels.push(label);
    }

    this.selector = this.add.image(SELECTOR_X, TOP_Y, "icon-tri-smol").setDepth(5);
    this.updateSelectorPosition();

    setChromeActions({
      confirm: true,
      confirmLabel: "Select",
      shuffle: false,
      zoom: false,
      back: true,
      backLabel: "Back",
      navigate: true,
    });

    onConfirm(this, () => this.confirmSelection());
    bindBack(this, () => this.goBack());
    bindUp(this, () => this.moveSelection(-1));
    bindDown(this, () => this.moveSelection(1));

    this.events.once(Phaser.Scenes.Events.SHUTDOWN, () => {
      setChromeActions({
        confirm: false,
        shuffle: false,
        zoom: false,
        back: false,
        navigate: false,
      });
    });
  }

  private soundManager(): SoundManager {
    return this.registry.get("sound") as SoundManager;
  }

  private updateSelectorPosition(): void {
    if (!this.selector) {
      return;
    }

    const option = this.options[this.selectedIndex];
    const label = this.optionLabels[this.selectedIndex];
    if (!option || !label) {
      return;
    }

    const textWidth = label.width;
    this.selector.setPosition(
      SELECTOR_X - textWidth / 2 - SELECTOR_OFFSET,
      option.y,
    );
  }

  private moveSelection(delta: number): void {
    this.soundManager().playABut();
    this.selectedIndex =
      (this.selectedIndex + delta + this.options.length) % this.options.length;
    this.updateSelectorPosition();
  }

  private toggleDeckOption(): void {
    const next = toggleDeckMode(getDeckMode(this.registry));
    setDeckMode(this.registry, next);

    const deckIndex = this.options.findIndex((option) => option.key === "deck");
    if (deckIndex < 0) {
      return;
    }

    const labelText = deckModeLabel(next);
    this.options[deckIndex]!.text = labelText;
    this.optionLabels[deckIndex]?.setText(labelText);
    this.updateSelectorPosition();
  }

  private confirmSelection(): void {
    const option = this.options[this.selectedIndex];
    if (!option) {
      return;
    }

    if (option.key !== "hahahaha") {
      this.soundManager().playABut();
    }

    switch (option.key) {
      case "how_to":
        this.soundManager().playSfx("sfx-tuin", { volume: 0.5 });
        this.scene.start("HowToScene");
        return;
      case "sound":
        this.soundManager().playABut();
        this.scene.start("SoundSettingsScene");
        return;
      case "deck":
        this.soundManager().playABut();
        this.toggleDeckOption();
        return;
      case "hahahaha":
        this.soundManager().playSfx("sfx-hahahaha", { volume: 1 });
        return;
      case "back":
        this.soundManager().playSfx("sfx-b-button", { volume: 0.5 });
        this.scene.start("MenuScene");
        return;
    }
  }

  private goBack(): void {
    this.soundManager().playSfx("sfx-b-button", { volume: 0.5 });
    this.scene.start("MenuScene");
  }
}
