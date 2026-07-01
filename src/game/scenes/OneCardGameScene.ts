import Phaser from "phaser";
import { GAME_HEIGHT, GAME_WIDTH, getCardImageUrl } from "../config";
import type { ReadingResult } from "../data/types";
import { AutoShuffleDriver, ShuffleInput } from "../systems/ShuffleInput";
import { Deck } from "../systems/Deck";
import { SoundManager } from "../systems/SoundManager";
import { addGameText, confirmPressed, createWrappedText, initSceneCamera, playSpritesheetOnce, type UiText } from "../systems/phaserUtils";

type GameState = "intro" | "shuffle" | "revealing" | "fortune" | "revealed";

const FIRST_PROMPTS = [
  "Set your intentions, let the cards\nhear your silent whispers.",
  "Let your energy flow... \nand the answers will find you.",
  "Clear your mind, focus your heart,\nand allow the truth to unfold.",
  "Shuffle with purpose. Your\nquestion shapes the path ahead.",
];

export class OneCardGameScene extends Phaser.Scene {
  private state: GameState = "intro";
  private deck = new Deck();
  private shuffleSprite?: Phaser.GameObjects.Sprite;
  private spinSlideSprite?: Phaser.GameObjects.Sprite;
  private placementSprite?: Phaser.GameObjects.Image;
  private cardSprite?: Phaser.GameObjects.Image;
  private promptText?: UiText;
  private shuffleInput?: ShuffleInput;
  private autoDriver?: AutoShuffleDriver;

  private shuffleFrame = 1;
  private shuffleFrameCount = 60;
  private shuffleSpinCount = 0;
  private spinSlideTriggerSpinCount = Phaser.Math.Between(5, 8);
  private spinSlideTriggered = false;

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

    this.cameras.main.setBackgroundColor("#d4edda");
    this.cameras.main.setVisible(true);

    this.add
      .rectangle(GAME_WIDTH / 2, GAME_HEIGHT / 2, GAME_WIDTH, GAME_HEIGHT, 0xd4edda)
      .setDepth(0);

    addGameText(this, 200, 120, "ONE CARD GAME", {
      fontSize: 20,
      align: "center",
    }).setOrigin(0.5);

    this.state = "intro";
    this.shuffleFrame = 1;
    this.shuffleSpinCount = 0;
    this.spinSlideTriggered = false;
    this.spinSlideTriggerSpinCount = Phaser.Math.Between(5, 8);

    this.add.image(200, 120, "playspace").setDepth(0);
    this.startDeckLayingIntro();
  }

  private soundManager(): SoundManager {
    return this.registry.get("sound") as SoundManager;
  }

  private startDeckLayingIntro(): void {
    const sprite = this.add.sprite(205, 120, "deck-laying", 0).setDepth(2);
    this.soundManager().playSfx("sfx-cards-slow", { volume: 1 });

    playSpritesheetOnce(sprite, "deck-laying-play", 30, () => {
      sprite.destroy();
      this.enterShuffle();
    });
  }

  private enterShuffle(): void {
    this.state = "shuffle";
    this.add.image(200, 120, "darkcloth").setDepth(1);

    this.shuffleSprite = this.add.sprite(220, 135, "shuffle", 0).setDepth(3);
    this.shuffleFrameCount = this.shuffleSprite.texture.frameTotal;
    this.shuffleFrame = 1;

    this.showPrompt(FIRST_PROMPTS[Math.floor(Math.random() * FIRST_PROMPTS.length)]);

    this.shuffleInput = new ShuffleInput(this, {
      centerX: 220,
      centerY: 135,
      radius: 70,
      onFrameAdvance: (steps) => this.advanceShuffleFrames(steps),
      onAutoShuffle: () => this.startAutoShuffle(),
    });
    this.shuffleInput.setDepth(20);

    this.autoDriver = new AutoShuffleDriver(
      this,
      (steps) => this.advanceShuffleFrames(steps),
      () => this.spinSlideTriggered,
    );
  }

  private showPrompt(text: string): void {
    this.promptText?.destroy();
    this.promptText = addGameText(this, 20, 20, text, {
      fontSize: 12,
      align: "left",
      wordWrap: { width: 360 },
    }).setOrigin(0, 0);
  }

  private clearPrompt(): void {
    this.promptText?.destroy();
    this.promptText = undefined;
  }

  private startAutoShuffle(): void {
    if (this.state !== "shuffle" || this.spinSlideTriggered) {
      return;
    }
    this.soundManager().startCrankLoop();
    this.autoDriver?.start();
  }

  private advanceShuffleFrames(frameAdvance: number): void {
    if (!this.shuffleSprite || this.spinSlideTriggered || this.state !== "shuffle") {
      return;
    }

    const steps = Math.abs(frameAdvance);
    if (steps === 0) {
      return;
    }

    const direction = frameAdvance > 0 ? 1 : -1;
    this.soundManager().startCrankLoop();

    for (let i = 0; i < steps; i += 1) {
      let nextFrame = this.shuffleFrame + direction;

      if (nextFrame > this.shuffleFrameCount) {
        nextFrame = 1;
        this.shuffleSpinCount += 1;
      } else if (nextFrame < 1) {
        nextFrame = this.shuffleFrameCount;
      }

      this.shuffleFrame = nextFrame;
      this.shuffleSprite.setFrame(this.shuffleFrame - 1);

      if (
        direction > 0 &&
        this.shuffleSpinCount >= this.spinSlideTriggerSpinCount &&
        this.shuffleFrame === 1
      ) {
        this.triggerSpinSlide();
        return;
      }
    }
  }

  private triggerSpinSlide(): void {
    if (this.spinSlideTriggered || this.state !== "shuffle") {
      return;
    }

    this.spinSlideTriggered = true;
    this.state = "revealing";
    this.autoDriver?.stop();
    this.soundManager().stopCrankLoop();
    this.clearPrompt();
    this.shuffleInput?.setVisible(false);

    this.shuffleSprite?.destroy();
    this.shuffleSprite = undefined;

    this.spinSlideSprite = this.add.sprite(205, 150, "spin-slide", 0).setDepth(3);
    this.soundManager().playSfx("sfx-cards-fast", { volume: 1 });

    playSpritesheetOnce(this.spinSlideSprite, "spin-slide-play", 30, () => {
      this.spinSlideSprite?.destroy();
      this.spinSlideSprite = undefined;
      this.showPlacementAndDraw();
    });
  }

  private showPlacementAndDraw(): void {
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
  }

  private drawSingleCard(): void {
    const result = this.deck.drawByFilter("full");
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

    const cardKey = `card-${result.cardSuit}-${result.cardNumber}`;
    const cardUrl = getCardImageUrl(result.cardNumber, result.cardSuit, false);

    if (!this.textures.exists(cardKey)) {
      this.load.image(cardKey, cardUrl);
      this.load.once(Phaser.Loader.Events.COMPLETE, () => this.placeCard(cardKey));
      this.load.start();
    } else {
      this.placeCard(cardKey);
    }
  }

  private placeCard(textureKey: string): void {
    if (!this.drawResult) {
      return;
    }

    this.cardSprite = this.add
      .image(200, 120, textureKey)
      .setDepth(4)
      .setScale(1);

    if (this.inverted) {
      this.cardSprite.setAngle(180);
    }

    this.state = "fortune";
    this.soundManager().playSfx("sfx-tuin", { volume: 0.5 });

    this.time.delayedCall(500, () => {
      this.state = "revealed";
      this.showRevealPrompt();
    });
  }

  private showRevealPrompt(): void {
    createWrappedText(this, 200, 210, "Tap to read your fortune", 360, {
      fontSize: 12,
    }).setDepth(10);
  }

  update(): void {
    if (this.state !== "revealed") {
      return;
    }

    if (confirmPressed(this) && this.drawResult) {
      this.soundManager().playSfx("sfx-a-but", { volume: 0.5 });
      this.scene.start("OneCardPostScene", { reading: this.drawResult });
    }
  }

  shutdown(): void {
    this.autoDriver?.stop();
    this.shuffleInput?.destroy();
    this.soundManager().stopCrankLoop();
  }
}
