import Phaser from "phaser";
import {
  bindBack,
  bindDown,
  bindUp,
  setChromeActions,
} from "../game/systems/GameInput";
import { createDinahSprite } from "../game/systems/dinah";
import {
  createWrappedText,
  initSceneCamera,
  onConfirm,
  type UiText,
} from "../game/systems/phaserUtils";
import { collectQaLines, groupStartIndexes, type QaLine } from "./qaLines";

const TEXT_BASE_Y = 182;
const SCROLL_BASE_Y = 170;
const OSC_AMPLITUDE = 3.7;
const OSC_SPEED = 2.5;

export class TextWrapQaScene extends Phaser.Scene {
  private lines: QaLine[] = [];
  private groupStarts: number[] = [];
  private lineIndex = 0;
  private textBox?: UiText;
  private scrollSprite?: Phaser.GameObjects.Image;
  private oscillationStart = 0;

  constructor() {
    super({ key: "TextWrapQaScene" });
  }

  create(): void {
    initSceneCamera(this);

    this.lines = collectQaLines();
    this.groupStarts = groupStartIndexes(this.lines);
    this.lineIndex = this.initialIndex();
    this.oscillationStart = this.time.now;

    createDinahSprite(this);
    this.scrollSprite = this.add.image(202, SCROLL_BASE_Y, "scroll-box").setDepth(2);

    setChromeActions({
      confirm: true,
      confirmLabel: "Next",
      back: true,
      backLabel: "Prev",
      shuffle: false,
      zoom: false,
      start: false,
      navigate: true,
    });

    onConfirm(this, () => this.go(1));
    bindBack(this, () => this.go(-1));
    bindUp(this, () => this.jumpGroup(-1));
    bindDown(this, () => this.jumpGroup(1));

    this.input.keyboard?.on("keydown-LEFT", () => this.go(-1));
    this.input.keyboard?.on("keydown-RIGHT", () => this.go(1));

    this.events.once(Phaser.Scenes.Events.SHUTDOWN, () => {
      setChromeActions({
        confirm: false,
        shuffle: false,
        zoom: false,
        back: false,
        navigate: false,
        start: false,
      });
    });

    this.showCurrentLine();
  }

  private initialIndex(): number {
    const query = new URLSearchParams(window.location.search).get("q")?.trim().toLowerCase();
    if (!query) {
      return 0;
    }
    const match = this.lines.findIndex((line) => {
      return `${line.group} ${line.source} ${line.text}`.toLowerCase().includes(query);
    });
    return match >= 0 ? match : 0;
  }

  private go(delta: number): void {
    if (this.lines.length === 0) {
      return;
    }
    this.lineIndex = (this.lineIndex + delta + this.lines.length) % this.lines.length;
    this.showCurrentLine();
  }

  private jumpGroup(delta: number): void {
    if (this.groupStarts.length === 0) {
      return;
    }
    let currentGroup = 0;
    for (let index = 0; index < this.groupStarts.length; index += 1) {
      const start = this.groupStarts[index] ?? 0;
      if (start <= this.lineIndex) {
        currentGroup = index;
      } else {
        break;
      }
    }
    const next = (currentGroup + delta + this.groupStarts.length) % this.groupStarts.length;
    this.lineIndex = this.groupStarts[next] ?? 0;
    this.showCurrentLine();
  }

  private showCurrentLine(): void {
    this.textBox?.destroy();
    const entry = this.lines[this.lineIndex];
    const text = (entry?.text ?? "").replace(/\*/g, "");
    this.textBox = createWrappedText(this, 190, TEXT_BASE_Y, text, 310, {
      fontSize: 20,
      color: "#323027",
    });
    this.updateCaption(entry, this.textBox.text);
  }

  private updateCaption(entry: QaLine | undefined, wrapped: string): void {
    const caption = document.getElementById("qa-meta");
    if (!caption) {
      return;
    }
    const wrapRows = wrapped.split("\n").length;
    caption.classList.toggle("is-overflow", wrapRows >= 4);
    caption.textContent = [
      `${this.lineIndex + 1} / ${this.lines.length}`,
      entry?.group ?? "",
      entry?.source ?? "",
      `wrap ${wrapRows}`,
    ]
      .filter(Boolean)
      .join("  ·  ");
  }

  update(): void {
    const elapsed = (this.time.now - this.oscillationStart) / 1000;
    const offset = OSC_AMPLITUDE * Math.sin(elapsed * OSC_SPEED);
    this.textBox?.setY(TEXT_BASE_Y + offset);
    this.scrollSprite?.setY(SCROLL_BASE_Y + offset);
  }
}
