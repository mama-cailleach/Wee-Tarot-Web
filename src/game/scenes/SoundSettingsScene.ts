import Phaser from "phaser";
import {
  bindBack,
  bindDown,
  bindUp,
  setChromeActions,
} from "../systems/GameInput";
import type { SoundManager, SoundMode } from "../systems/SoundManager";
import {
  addGameText,
  initSceneCamera,
  onConfirm,
  type UiText,
} from "../systems/phaserUtils";

const BG_LABELS = ["Music&Rain", "Music", "Rain"] as const;
const SFX_LABELS = ["On", "Off"] as const;
const ROW_LABELS = ["BG", "SFX", "Back"] as const;
const ROW_Y = [98, 138, 212] as const;

const TITLE_X = 120;
const OPTION_X = 280;
const SELECTOR_OFFSET = 45;

type SoundRow = 0 | 1 | 2;

export class SoundSettingsScene extends Phaser.Scene {
  private selectedRow: SoundRow = 0;
  private bgOptionIndex = 0;
  private sfxOptionIndex = 0;
  private selector?: Phaser.GameObjects.Image;
  private bgValueText?: UiText;
  private sfxValueText?: UiText;

  constructor() {
    super({ key: "SoundSettingsScene" });
  }

  create(): void {
    initSceneCamera(this);

    const sound = this.soundManager();
    this.selectedRow = 0;
    this.bgOptionIndex = sound.getSoundMode() - 1;
    this.sfxOptionIndex = sound.getSfxEnabled() ? 0 : 1;

    this.add.image(200, 120, "darkcloth").setDepth(0);

    addGameText(this, 200, 40, "SOUNDS", {
      fontSize: 20,
      align: "center",
    }).setOrigin(0.5, 0.5);

    addGameText(this, TITLE_X - 10, ROW_Y[0], "BG", {
      fontSize: 20,
      align: "center",
    }).setOrigin(0.5, 0.5);

    this.bgValueText = addGameText(
      this,
      this.bgValueX(),
      ROW_Y[0],
      BG_LABELS[this.bgOptionIndex]!,
      { fontSize: 20, align: "center" },
    ).setOrigin(0.5, 0.5);

    addGameText(this, TITLE_X, ROW_Y[1], "SFX", {
      fontSize: 20,
      align: "center",
    }).setOrigin(0.5, 0.5);

    this.sfxValueText = addGameText(
      this,
      OPTION_X,
      ROW_Y[1],
      SFX_LABELS[this.sfxOptionIndex]!,
      { fontSize: 20, align: "center" },
    ).setOrigin(0.5, 0.5);

    addGameText(this, 200, ROW_Y[2], "Back", {
      fontSize: 20,
      align: "center",
    }).setOrigin(0.5, 0.5);

    this.selector = this.add.image(TITLE_X, ROW_Y[0], "icon-tri-smol").setDepth(5);
    this.updateSelectorPosition();

    setChromeActions({
      confirm: true,
      shuffle: false,
      zoom: false,
      back: true,
      navigate: true,
      start: false,
    });

    onConfirm(this, () => this.handleConfirm());
    bindBack(this, () => this.goBack(true));
    bindUp(this, () => this.moveRow(-1));
    bindDown(this, () => this.moveRow(1));

    const onLeft = () => this.cycleCurrent(-1);
    const onRight = () => this.cycleCurrent(1);
    this.input.keyboard?.on("keydown-LEFT", onLeft);
    this.input.keyboard?.on("keydown-RIGHT", onRight);

    this.events.once(Phaser.Scenes.Events.SHUTDOWN, () => {
      this.input.keyboard?.off("keydown-LEFT", onLeft);
      this.input.keyboard?.off("keydown-RIGHT", onRight);
      setChromeActions({
        confirm: false,
        shuffle: false,
        zoom: false,
        back: false,
        navigate: false,
        start: false,
      });
    });
  }

  private soundManager(): SoundManager {
    return this.registry.get("sound") as SoundManager;
  }

  private bgValueX(): number {
    return this.bgOptionIndex === 0 ? OPTION_X - 20 : OPTION_X;
  }

  private updateSelectorPosition(): void {
    if (!this.selector) {
      return;
    }

    const y = ROW_Y[this.selectedRow]! - 2;
    const rowLabel = ROW_LABELS[this.selectedRow]!;

    if (this.selectedRow === 2) {
      this.selector.setAngle(90);
      this.selector.setPosition(200, y - 25);
      return;
    }

    this.selector.setAngle(180);
    if (this.selectedRow === 1) {
      this.selector.setPosition(TITLE_X + SELECTOR_OFFSET, y);
    } else {
      // Approximate Playdate: titlePostion - textWidth/2 + offset
      const approxHalfWidth = rowLabel.length * 5;
      this.selector.setPosition(TITLE_X - approxHalfWidth + SELECTOR_OFFSET, y);
    }
  }

  private moveRow(delta: number): void {
    this.soundManager().playABut();
    this.selectedRow = ((this.selectedRow + delta + 3) % 3) as SoundRow;
    this.updateSelectorPosition();
  }

  private cycleCurrent(direction: number): void {
    if (this.selectedRow === 2) {
      return;
    }

    this.soundManager().playABut();
    if (this.selectedRow === 0) {
      this.cycleBgOption(direction);
    } else {
      this.cycleSfxOption(direction);
    }
  }

  private cycleBgOption(direction: number): void {
    const count = BG_LABELS.length;
    this.bgOptionIndex = (this.bgOptionIndex + direction + count) % count;
    const mode = (this.bgOptionIndex + 1) as SoundMode;
    const sound = this.soundManager();
    sound.setSoundMode(mode);
    if (mode !== 2) {
      sound.setAmbienceVolume(0.6);
      sound.playAmbience();
    }

    this.bgValueText?.setText(BG_LABELS[this.bgOptionIndex]!);
    this.bgValueText?.setX(this.bgValueX());
  }

  private cycleSfxOption(direction: number): void {
    const count = SFX_LABELS.length;
    this.sfxOptionIndex = (this.sfxOptionIndex + direction + count) % count;
    this.soundManager().setSfxEnabled(this.sfxOptionIndex === 0);
    this.sfxValueText?.setText(SFX_LABELS[this.sfxOptionIndex]!);
  }

  private handleConfirm(): void {
    if (this.selectedRow === 2) {
      this.soundManager().playABut();
      this.goBack(false);
      return;
    }

    this.soundManager().playABut();
    if (this.selectedRow === 0) {
      this.cycleBgOption(1);
    } else {
      this.cycleSfxOption(1);
    }
  }

  private goBack(fromBackButton: boolean): void {
    if (fromBackButton) {
      this.soundManager().playSfx("sfx-b-button", { volume: 0.5 });
    }
    this.soundManager().playSfx("sfx-b-button", { volume: 1 });
    this.scene.start("SettingsScene");
  }
}
