# Wee Tarot Web

Web port of [Wee Tarot](https://mama666.itch.io/wee-tarot). This repo is separate from the Playdate version.

**Play in browser:** [https://mama-cailleach.github.io/Wee-Tarot-Web/](https://mama-cailleach.github.io/Wee-Tarot-Web/)

**Canonical Playdate repo:** `C:\Games\Playdate\mama Games\Wee Tarot`

## Layout

| Path | Purpose |
|------|---------|
| `assets/` | Images, audio, fonts (copied from Playdate) |
| `content/` | Card copy, spread text (Lua source for export) |
| `src/` | Phaser 3 + TypeScript web game |
| `reference/playdate/` | Read-only Playdate Lua for architecture reference |
| `docs/` | Porting notes, flow maps, [GitHub Pages hosting](docs/github-pages.md) |

See [MIGRATION.md](MIGRATION.md) for the full copy manifest.

## Development

Requires **Node.js 20+**.

```bash
npm install
npm run export:data    # or: npm run export:data:ps on Windows without Node for export only
npm run dev
```

Open the URL shown in the terminal (default `http://localhost:5173`).

## Vertical slice

Title → one-card shuffle (spin or auto) → draw → Dinah reading → back to title.

## Build

```bash
npm run build
npm run preview
```

Push to `master` publishes the live site automatically. Details: [docs/github-pages.md](docs/github-pages.md).

## Tests

```bash
npm test
```
