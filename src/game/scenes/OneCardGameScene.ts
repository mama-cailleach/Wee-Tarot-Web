import Phaser from "phaser";
import { getCardImageUrl } from "../config";
import type { ReadingResult } from "../data/types";
import { Deck } from "../systems/Deck";
import { getDeckMode } from "../systems/deckMode";
import { bindAutoShuffle, bindZoom, setChromeActions } from "../systems/GameInput";
import { SoundManager } from "../systems/SoundManager";
import {
  addGameText,
  fitImageToGameFrame,
  initSceneCamera,
  loadTextureFromUrl,
  onConfirm,
  playSpritesheetOnce,
  type UiText,
} from "../systems/phaserUtils";

type GameState = "intro" | "shuffle" | "revealing" | "fortune" | "revealed";

const FIRST_PROMPTS = [
  "Set your intentions, let the cards hear your silent whispers.",
  "Let your energy flow... and the answers will find you.",
  "Clear your mind, focus your heart, and allow the truth to unfold.",
  "Shuffle with purpose. Your question shapes the path ahead.",
];

export class OneCardGameScene extends Phaser.Scene {
  private state: GameState = "intro";
  private deck = new Deck();
  private bgImage?: Phaser.GameObjects.Image;
  private shuffleSprite?: Phaser.GameObjects.Sprite;
  private fxSprite?: Phaser.GameObjects.Sprite;
  private placementSprite?: Phaser.GameObjects.Image;
  private cardSprite?: Phaser.GameObjects.Image;
  private promptText?: UiText;
  private shuffleStarted = false;
  private shuffleFrameHandler?: (
    animation: Phaser.Animations.Animation,
    frame: Phaser.Animations.AnimationFrame,
  ) => void;
  private cardZoomed = false;
  private zoomToggleBusy = false;

  private drawResult?: ReadingResult;
  private inverted = false;

  constructor() {
    super({ key: "OneCardGameScene" });
  }

  create(): void {
    initSceneCamera(this);

    if (!this.registry.get("sound")) {
      this.registry.set("sound", new SoundManager(this));
    }

    console.log(
      "[OneCardGameScene] create — scene:",
      this.scene.key,
      "playspace:",
      this.textures.exists("playspace"),
    );

    this.cameras.main.setBackgroundColor("#000000");
    this.cameras.main.setVisible(true);

    this.bgImage = this.add.image(200, 120, "playspace").setDepth(0);

    this.state = "intro";
    this.shuffleStarted = false;
    this.cardZoomed = false;
    this.zoomToggleBusy = false;

    setChromeActions({ confirm: false, shuffle: false, zoom: false, back: false });
    onConfirm(this, () => this.tryOpenReading(), { canvasTap: false });
    bindAutoShuffle(this, () => this.startShuffleSequence());
    bindZoom(this, () => this.toggleCardZoom());

    this.startDeckLayingIntro();
  }

  private soundManager(): SoundManager {
    return this.registry.get("sound") as SoundManager;
  }

  private startDeckLayingIntro(): void {
    const sprite = this.add.sprite(200, 120, "deck-laying", 0).setDepth(2);
    this.soundManager().playSfx("sfx-cards-slow", { volume: 1 });

    playSpritesheetOnce(sprite, "deck-laying-play", 30, () => {
      sprite.destroy();
      this.enterShuffle();
    });
  }

  private enterShuffle(): void {
    this.state = "shuffle";
    this.shuffleStarted = false;

    this.shuffleSprite = this.add
      .sprite(207, 130, "shuffle", 0)
      .setDepth(3)
      .setInteractive({ useHandCursor: true });

    this.shuffleSprite.on("pointerdown", () => this.startShuffleSequence());

    this.showPrompt(FIRST_PROMPTS[Math.floor(Math.random() * FIRST_PROMPTS.length)]);
    setChromeActions({ confirm: false, shuffle: true, zoom: false, back: false });
  }

  private showPrompt(text: string): void {
    this.promptText?.destroy();
    this.promptText = addGameText(this, 10, 0, text, {
      fontSize: 20,
      align: "left",
      wordWrap: { width: 380 },
    }).setOrigin(0, 0);
  }

  private clearPrompt(): void {
    this.promptText?.destroy();
    this.promptText = undefined;
  }

  private startShuffleSequence(): void {
    if (this.state !== "shuffle" || this.shuffleStarted || !this.shuffleSprite) {
      return;
    }

    this.shuffleStarted = true;
    setChromeActions({ confirm: false, shuffle: false, zoom: false, back: false });
    this.shuffleSprite.disableInteractive();
    this.clearPrompt();

    const loops = Phaser.Math.Between(3, 6);
    const sprite = this.shuffleSprite;
    this.soundManager().startCrankLoop();
    this.shuffleFrameHandler = (_animation, frame) => {
      if (frame.index === 1) {
        this.soundManager().startCrankLoop();
      }
    };
    sprite.on(Phaser.Animations.Events.ANIMATION_UPDATE, this.shuffleFrameHandler);

    playSpritesheetOnce(
      sprite,
      "shuffle-play",
      30,
      () => {
        this.clearShuffleCrankSync();
        this.soundManager().stopCrankLoop();
        this.shuffleSprite?.destroy();
        this.shuffleSprite = undefined;
        this.playExplodeDeck();
      },
      loops - 1,
    );
  }

  private playExplodeDeck(): void {
    this.state = "revealing";
    this.fxSprite = this.add.sprite(194, 122, "explode-deck", 0).setDepth(3);
    this.soundManager().playSfx("sfx-cards-fast", { volume: 1 });

    playSpritesheetOnce(this.fxSprite, "explode-deck-play", 30, () => {
      this.fxSprite?.destroy();
      this.fxSprite = undefined;
      this.showPlacementAndDraw();
    });
  }

  private showPlacementAndDraw(): void {
    // Swap the playspace background for the darkcloth at the reveal step.
    this.bgImage?.setTexture("darkcloth");

    this.placementSprite = this.add
      .image(200, 120, "placement-diamond")
      .setDepth(2)
      .setAlpha(0);

    this.tweens.add({
      targets: this.placementSprite,
      alpha: 1,
      duration: 300,
      onComplete: () => this.drawSingleCard(),
    });
    this.soundManager().playSfx("sfx-tuin", { volume: 0.5 });
  }

  private cardTextureKey(zoomed: boolean): string {
    if (!this.drawResult) {
      return "";
    }
    const base = `card-${this.drawResult.cardSuit}-${this.drawResult.cardNumber}`;
    return zoomed ? `${base}-zoom` : base;
  }

  private drawSingleCard(): void {
    const result = this.deck.drawByFilter(getDeckMode(this.registry));
    if (!result) {
      return;
    }

    this.inverted = this.deck.rollInverted();
    this.drawResult = {
      cardName: result.cardName,
      cardNumber: result.cardNumber,
      cardSuit: result.cardSuit,
      inverted: this.inverted,
    };
    this.cardZoomed = false;

    const cardKey = this.cardTextureKey(false);
    const cardUrl = getCardImageUrl(result.cardNumber, result.cardSuit, false);
    loadTextureFromUrl(this, cardKey, cardUrl, (key) => this.placeCard(key));
  }

  private placeCard(textureKey: string): void {
    if (!this.drawResult) {
      return;
    }

    this.cardSprite = this.add.image(200, 120, textureKey).setDepth(4);
    fitImageToGameFrame(this.cardSprite);

    if (this.inverted) {
      this.cardSprite.setAngle(180);
    }

    this.state = "fortune";
    this.soundManager().playSfx("sfx-tuin", { volume: 0.5 });

    this.time.delayedCall(500, () => {
      this.state = "revealed";
      setChromeActions({
        confirm: true,
        confirmLabel: "Continue",
        shuffle: false,
        zoom: true,
        back: false,
      });
    });
  }

  private toggleCardZoom(): void {
    if (
      (this.state !== "revealed" && this.state !== "fortune") ||
      !this.drawResult ||
      !this.cardSprite ||
      this.zoomToggleBusy
    ) {
      return;
    }

    const nextZoomed = !this.cardZoomed;
    const textureKey = this.cardTextureKey(nextZoomed);

    const apply = (): void => {
      this.cardSprite?.setTexture(textureKey);
      fitImageToGameFrame(this.cardSprite);
      if (this.inverted) {
        this.cardSprite?.setAngle(180);
      }
      this.cardZoomed = nextZoomed;
      this.zoomToggleBusy = false;
    };

    if (this.textures.exists(textureKey)) {
      apply();
      return;
    }

    this.zoomToggleBusy = true;
    const url = getCardImageUrl(
      this.drawResult.cardNumber,
      this.drawResult.cardSuit,
      nextZoomed,
    );
    loadTextureFromUrl(this, textureKey, url, (key) => {
      if (!this.textures.exists(key) || !this.cardSprite) {
        this.zoomToggleBusy = false;
        return;
      }
      apply();
    });
  }

  private clearShuffleCrankSync(): void {
    if (this.shuffleSprite && this.shuffleFrameHandler) {
      this.shuffleSprite.off(
        Phaser.Animations.Events.ANIMATION_UPDATE,
        this.shuffleFrameHandler,
      );
    }
    this.shuffleFrameHandler = undefined;
  }

  private tryOpenReading(): void {
    if (this.state !== "revealed" || !this.drawResult) {
      return;
    }
    this.soundManager().playABut();
    this.soundManager().playSfx("sfx-tuin", { volume: 1 });
    this.scene.start("OneCardPostScene", { reading: this.drawResult });
  }

  shutdown(): void {
    this.clearShuffleCrankSync();
    this.soundManager().stopCrankLoop();
    setChromeActions({ confirm: false, shuffle: false, zoom: false, back: false });
  }
}
