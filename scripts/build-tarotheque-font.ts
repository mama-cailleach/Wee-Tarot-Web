import { readFileSync, writeFileSync } from "node:fs";
import path from "node:path";
import { PNG } from "pngjs";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, "..");
const fontsDir = path.join(root, "assets", "fonts");

interface Glyph {
  char: string;
  advance: number;
  index: number;
}

function parsePlaydateFnt(content: string): { baseline: number; tracking: number; glyphs: Glyph[] } {
  let baseline = 0;
  let tracking = 0;
  const glyphs: Glyph[] = [];

  for (const rawLine of content.split(/\r?\n/)) {
    const line = rawLine.trim();
    if (!line || line.startsWith("--")) {
      const metricsMatch = line.match(/"baseline":(\d+)/);
      if (metricsMatch) {
        baseline = Number(metricsMatch[1]);
      }
      continue;
    }

    if (line.startsWith("tracking=")) {
      tracking = Number(line.slice("tracking=".length));
      continue;
    }

    const match = line.match(/^(.+?)\s+(-?\d+)$/);
    if (!match) {
      continue;
    }

    let char = match[1];
    if (char === "space") {
      char = " ";
    }

    if (char.length > 1) {
      continue;
    }

    glyphs.push({
      char,
      advance: Number(match[2]) + tracking,
      index: glyphs.length,
    });
  }

  return { baseline, tracking, glyphs };
}

function parseTableSize(filename: string): { cellWidth: number; cellHeight: number } {
  const match = filename.match(/-table-(\d+)-(\d+)\.png$/);
  if (!match) {
    throw new Error(`Cannot parse table size from ${filename}`);
  }

  return {
    cellWidth: Number(match[1]),
    cellHeight: Number(match[2]),
  };
}

/**
 * The Playdate atlas already stores the glyph silhouette in the alpha channel
 * (glyph = alpha 255, background = alpha 0). Phaser tints by multiplying against
 * the glyph pixels, so we force every pixel to white and keep the original alpha.
 * This makes the glyph shape tintable and leaves the background transparent.
 */
function convertPlaydateAtlas(inputPath: string, outputPath: string): { width: number; height: number } {
  const png = PNG.sync.read(readFileSync(inputPath));

  for (let i = 0; i < png.data.length; i += 4) {
    const alpha = png.data[i + 3];
    png.data[i] = 255;
    png.data[i + 1] = 255;
    png.data[i + 2] = 255;
    png.data[i + 3] = alpha;
  }

  writeFileSync(outputPath, PNG.sync.write(png));
  return { width: png.width, height: png.height };
}

function buildBmFontXml(
  fontName: string,
  atlasFile: string,
  atlasWidth: number,
  atlasHeight: number,
  cellWidth: number,
  cellHeight: number,
  baseline: number,
  glyphs: Glyph[],
): string {
  const cols = Math.floor(atlasWidth / cellWidth);
  const chars = glyphs
    .map((glyph) => {
      const col = glyph.index % cols;
      const row = Math.floor(glyph.index / cols);
      const id = glyph.char.codePointAt(0) ?? 0;
      const x = col * cellWidth;
      const y = row * cellHeight;
      const width = Math.max(1, Math.min(glyph.advance, cellWidth));

      return `    <char id="${id}" x="${x}" y="${y}" width="${width}" height="${cellHeight}" xoffset="0" yoffset="0" xadvance="${glyph.advance}" page="0" chnl="15"/>`;
    })
    .join("\n");

  return `<?xml version="1.0"?>
<font>
  <info face="${fontName}" size="20" bold="0" italic="0" charset="" unicode="1" stretchH="100" smooth="0" aa="1" padding="0,0,0,0" spacing="0,0" outline="0"/>
  <common lineHeight="${cellHeight}" base="${baseline}" scaleW="${atlasWidth}" scaleH="${atlasHeight}" pages="1" packed="0" alphaChnl="1" redChnl="0" greenChnl="0" blueChnl="0"/>
  <pages>
    <page id="0" file="${atlasFile}"/>
  </pages>
  <chars count="${glyphs.length}">
${chars}
  </chars>
</font>
`;
}

function buildFontSet(version: "v2" | "v1"): void {
  const fntName = `tarotheque-${version}-20.fnt`;
  const sourcePngName =
    version === "v2" ? "tarotheque-v2-20-table-30-36.png" : "tarotheque-v1-20-table-29-35.png";
  const atlasName = `tarotheque-${version}-20-atlas.png`;
  const xmlName = `tarotheque-${version}-20.xml`;

  const fntPath = path.join(fontsDir, fntName);
  const sourcePngPath = path.join(fontsDir, sourcePngName);
  const atlasPath = path.join(fontsDir, atlasName);
  const xmlPath = path.join(fontsDir, xmlName);

  const fnt = readFileSync(fntPath, "utf8");
  const { baseline, glyphs } = parsePlaydateFnt(fnt);
  const { cellWidth, cellHeight } = parseTableSize(sourcePngName);
  const { width: atlasWidth, height: atlasHeight } = convertPlaydateAtlas(sourcePngPath, atlasPath);

  const xml = buildBmFontXml(
    `tarotheque-${version}`,
    atlasName,
    atlasWidth,
    atlasHeight,
    cellWidth,
    cellHeight,
    baseline,
    glyphs,
  );

  writeFileSync(xmlPath, xml, "utf8");
  console.log(`Wrote ${atlasName} + ${xmlName} (${glyphs.length} glyphs)`);
}

buildFontSet("v2");
buildFontSet("v1");
