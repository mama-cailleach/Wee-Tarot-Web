import Phaser from "phaser";

export interface ShuffleInputConfig {
  centerX: number;
  centerY: number;
  radius: number;
  onFrameAdvance: (steps: number) => void;
}

/** Canvas drag-to-crank zone. Auto-shuffle lives on the HTML chrome under the frame. */
export class ShuffleInput {
  private pointerId: number | null = null;
  private lastAngle: number | null = null;
  private accumulated = 0;
  private readonly spinThreshold = 0.35;

  private spinZone: Phaser.GameObjects.Zone;

  constructor(
    private readonly scene: Phaser.Scene,
    private readonly config: ShuffleInputConfig,
  ) {
    this.spinZone = scene.add
      .zone(config.centerX, config.centerY, config.radius * 2.2, config.radius * 2.2)
      .setInteractive({ useHandCursor: true });

    this.bindEvents();
  }

  private bindEvents(): void {
    this.spinZone.on("pointerdown", (pointer: Phaser.Input.Pointer) => {
      this.pointerId = pointer.id;
      this.lastAngle = this.angleFromPointer(pointer);
      this.accumulated = 0;
    });

    this.scene.input.on("pointermove", (pointer: Phaser.Input.Pointer) => {
      if (this.pointerId !== pointer.id || !pointer.isDown) {
        return;
      }

      const angle = this.angleFromPointer(pointer);
      if (this.lastAngle === null) {
        this.lastAngle = angle;
        return;
      }

      let delta = angle - this.lastAngle;
      if (delta > Math.PI) {
        delta -= Math.PI * 2;
      } else if (delta < -Math.PI) {
        delta += Math.PI * 2;
      }

      this.lastAngle = angle;
      this.accumulated += Math.abs(delta);

      while (this.accumulated >= this.spinThreshold) {
        this.accumulated -= this.spinThreshold;
        const direction = delta >= 0 ? 1 : -1;
        this.config.onFrameAdvance(direction);
      }
    });

    const endDrag = (pointer: Phaser.Input.Pointer) => {
      if (this.pointerId === pointer.id) {
        this.pointerId = null;
        this.lastAngle = null;
        this.accumulated = 0;
      }
    };

    this.scene.input.on("pointerup", endDrag);
    this.scene.input.on("pointerupoutside", endDrag);
  }

  private angleFromPointer(pointer: Phaser.Input.Pointer): number {
    return Math.atan2(pointer.y - this.config.centerY, pointer.x - this.config.centerX);
  }

  setDepth(depth: number): void {
    this.spinZone.setDepth(depth);
  }

  setVisible(visible: boolean): void {
    this.spinZone.setVisible(visible);
    this.spinZone.disableInteractive();
    if (visible) {
      this.spinZone.setInteractive({ useHandCursor: true });
    }
  }

  destroy(): void {
    this.spinZone.destroy();
  }
}

export class AutoShuffleDriver {
  private timer?: Phaser.Time.TimerEvent;
  private active = false;

  constructor(
    private readonly scene: Phaser.Scene,
    private readonly onFrameAdvance: (steps: number) => void,
    private readonly isComplete: () => boolean,
  ) {}

  start(): void {
    if (this.active) {
      return;
    }

    this.active = true;
    this.timer = this.scene.time.addEvent({
      delay: 33,
      loop: true,
      callback: () => {
        if (this.isComplete()) {
          this.stop();
          return;
        }
        this.onFrameAdvance(1);
      },
    });
  }

  stop(): void {
    this.timer?.remove();
    this.timer = undefined;
    this.active = false;
  }

  isRunning(): boolean {
    return this.active;
  }
}
