/**
 * Repack Playdate-style horizontal strip spritesheets into grids that fit under
 * WebGL MAX_TEXTURE_SIZE (commonly 4096–8192). Oversized strips load as black
 * quads in Phaser/WebGL even though the HTTP fetch succeeds.
 *
 * Usage: npx tsx scripts/repack-spritesheets.ts
 */
import { readFileSync, writeFileSync } from "node:fs";
import path from "node:path";
import { PNG } from "pngjs";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, "..");

/** Conservative limit that works on virtually all WebGL devices. */
const MAX_TEXTURE_SIZE = 4096;

interface Target {
  relativePath: string;
}

const TARGETS: Target[] = [
  { relativePath: "assets/images/shuffleAnimation/1_card_shuffle-table-400-240.png" },
  { relativePath: "assets/images/shuffleAnimation/card_spin_slide-table-400-240.png" },
  { relativePath: "assets/images/shuffleAnimation/deck_laying_full_lower-table-400-240.png" },
  { relativePath: "assets/images/shuffleAnimation/explode_finale-table-400-240.png" },
  { relativePath: "assets/images/shuffleAnimation/exploding_deck1-table-400-240.png" },
  { relativePath: "assets/images/shuffleAnimation/scaled_card-table-400-240.png" },
  { relativePath: "assets/images/bg/dinahBG-table-400-266.png" },
];

function parseTableSize(filename: string): { frameWidth: number; frameHeight: number } {
  const match = filename.match(/-table-(\d+)-(\d+)\.png$/i);
  if (!match) {
    throw new Error(`Cannot parse -table-W-H from ${filename}`);
  }
  return {
    frameWidth: Number(match[1]),
    frameHeight: Number(match[2]),
  };
}

function blitFrame(
  src: PNG,
  dst: PNG,
  srcX: number,
  srcY: number,
  dstX: number,
  dstY: number,
  frameWidth: number,
  frameHeight: number,
): void {
  for (let y = 0; y < frameHeight; y += 1) {
    const srcStart = ((srcY + y) * src.width + srcX) * 4;
    const dstStart = ((dstY + y) * dst.width + dstX) * 4;
    src.data.copy(dst.data, dstStart, srcStart, srcStart + frameWidth * 4);
  }
}

function repack(filePath: string): { skipped: boolean; reason?: string; before?: string; after?: string } {
  const { frameWidth, frameHeight } = parseTableSize(path.basename(filePath));
  const png = PNG.sync.read(readFileSync(filePath));

  if (png.width <= MAX_TEXTURE_SIZE && png.height <= MAX_TEXTURE_SIZE) {
    return {
      skipped: true,
      reason: `already within ${MAX_TEXTURE_SIZE} (${png.width}x${png.height})`,
    };
  }

  if (png.width % frameWidth !== 0 || png.height % frameHeight !== 0) {
    throw new Error(
      `${filePath}: size ${png.width}x${png.height} is not a multiple of frame ${frameWidth}x${frameHeight}`,
    );
  }

  const srcCols = png.width / frameWidth;
  const srcRows = png.height / frameHeight;
  const frameCount = srcCols * srcRows;

  const maxCols = Math.floor(MAX_TEXTURE_SIZE / frameWidth);
  const maxRows = Math.floor(MAX_TEXTURE_SIZE / frameHeight);
  if (maxCols < 1 || maxRows < 1) {
    throw new Error(`${filePath}: frame ${frameWidth}x${frameHeight} exceeds MAX_TEXTURE_SIZE`);
  }

  const cols = Math.min(maxCols, frameCount);
  const rows = Math.ceil(frameCount / cols);
  if (rows > maxRows) {
    throw new Error(
      `${filePath}: need ${rows} rows for ${frameCount} frames, but max is ${maxRows} under ${MAX_TEXTURE_SIZE}`,
    );
  }

  const out = new PNG({ width: cols * frameWidth, height: rows * frameHeight, colorType: 6 });
  out.data.fill(0);

  for (let i = 0; i < frameCount; i += 1) {
    const srcCol = i % srcCols;
    const srcRow = Math.floor(i / srcCols);
    const dstCol = i % cols;
    const dstRow = Math.floor(i / cols);

    blitFrame(
      png,
      out,
      srcCol * frameWidth,
      srcRow * frameHeight,
      dstCol * frameWidth,
      dstRow * frameHeight,
      frameWidth,
      frameHeight,
    );
  }

  writeFileSync(filePath, PNG.sync.write(out, { deflateLevel: 9, deflateStrategy: 3 }));

  return {
    skipped: false,
    before: `${png.width}x${png.height} (${frameCount} frames, ${srcCols}x${srcRows})`,
    after: `${out.width}x${out.height} (${cols}x${rows} grid)`,
  };
}

function main(): void {
  console.log(`Repacking spritesheets to fit under ${MAX_TEXTURE_SIZE}px…\n`);

  for (const target of TARGETS) {
    const filePath = path.join(root, target.relativePath);
    const result = repack(filePath);
    if (result.skipped) {
      console.log(`SKIP  ${target.relativePath} — ${result.reason}`);
    } else {
      console.log(`OK    ${target.relativePath}`);
      console.log(`      ${result.before} → ${result.after}`);
    }
  }
}

main();
