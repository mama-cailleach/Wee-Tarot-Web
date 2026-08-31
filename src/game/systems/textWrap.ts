export type MeasureTextWidth = (text: string) => number;

/**
 * Word-wrap like Playdate `utils.wrapParagraphToWidth` / `spriteWithText`.
 * A word stays on the current line when `current + " " + word` is <= maxWidth.
 * Trailing spaces are not counted — unlike Phaser BitmapText `setMaxWidth`.
 */
export function wrapTextToWidth(
  text: string,
  maxWidth: number,
  measure: MeasureTextWidth,
): string {
  if (maxWidth <= 0) {
    return text;
  }

  return splitParagraphs(text)
    .map((paragraph) => wrapParagraphToWidth(paragraph, maxWidth, measure).join("\n"))
    .join("\n");
}

function splitParagraphs(text: string): string[] {
  return text.split("\n");
}

function wrapParagraphToWidth(
  paragraph: string,
  maxWidth: number,
  measure: MeasureTextWidth,
): string[] {
  if (paragraph === "") {
    return [""];
  }

  const wrappedLines: string[] = [];
  let currentLine = "";

  const pushCurrentLine = (): void => {
    if (currentLine !== "") {
      wrappedLines.push(currentLine);
      currentLine = "";
    }
  };

  const breakLongWord = (word: string): void => {
    let chunk = "";
    for (const character of word) {
      const candidate = chunk + character;
      if (measure(candidate) <= maxWidth || chunk === "") {
        chunk = candidate;
      } else {
        wrappedLines.push(chunk);
        chunk = character;
      }
    }

    if (chunk.length === 0) {
      return;
    }

    if (currentLine === "") {
      currentLine = chunk;
      return;
    }

    const combined = `${currentLine} ${chunk}`;
    if (measure(combined) <= maxWidth) {
      currentLine = combined;
    } else {
      pushCurrentLine();
      currentLine = chunk;
    }
  };

  for (const word of paragraph.match(/\S+/g) ?? []) {
    if (currentLine === "") {
      if (measure(word) <= maxWidth) {
        currentLine = word;
      } else {
        breakLongWord(word);
      }
      continue;
    }

    const candidate = `${currentLine} ${word}`;
    if (measure(candidate) <= maxWidth) {
      currentLine = candidate;
    } else {
      pushCurrentLine();
      if (measure(word) <= maxWidth) {
        currentLine = word;
      } else {
        breakLongWord(word);
      }
    }
  }

  pushCurrentLine();
  return wrappedLines;
}
