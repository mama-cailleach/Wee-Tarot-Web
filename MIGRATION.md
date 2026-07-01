# Migration manifest

Content copied from the Playdate repo into this web project. **No files were modified in the source repo** — copy-only.

| | |
|---|---|
| **Source** | `C:\Games\Playdate\mama Games\Wee Tarot` |
| **Destination** | `C:\Games\Wee Tarot Web` |
| **Date** | 2026-07-01 |
| **Files copied from Playdate** | 295 |
| **New project files** | 3 (`README.md`, `.gitignore`, `MIGRATION.md`) |
| **Total files** | 298 |
| **Total size** | ~30 MB |

---

## Directory layout

```
Wee Tarot Web/
├── assets/          # Art, audio, fonts (ready for web engine)
├── content/         # Portable game data (Lua — convert when stack is chosen)
├── reference/       # Playdate Lua as design/spec reference (do not compile as-is)
├── docs/            # Planning and flow documentation
├── LICENSE
├── README.md
└── MIGRATION.md     # this file
```

---

## What was migrated

### `assets/` — 245 files (~29 MB)

| Subfolder | Count | Source | Notes |
|-----------|-------|--------|-------|
| `assets/images/bg/` | 24 | `source/images/bg/` | Backgrounds, journal, diary anim sheets, title anim |
| `assets/images/cups/` | 28 | `source/images/cups/` | Card faces + zoom variants |
| `assets/images/majorArcana/` | 44 | `source/images/majorArcana/` | Card faces + zoom variants |
| `assets/images/pentacles/` | 28 | `source/images/pentacles/` | Card faces + zoom variants |
| `assets/images/swords/` | 28 | `source/images/swords/` | Card faces + zoom variants |
| `assets/images/wands/` | 28 | `source/images/wands/` | Card faces + zoom variants |
| `assets/images/shuffleAnimation/` | 7 | `source/images/shuffleAnimation/` | Sprite sheets for shuffle/reveal |
| `assets/images/spreads/` | 10 | `source/images/spreads/` | Spread selection thumbnails + zoom |
| `assets/images/decknback/` | 2 | `source/images/decknback/` | Placement zone overlays |
| `assets/images/textscroll/` | 1 | `source/images/textscroll/` | Scroll box UI |
| `assets/sound/` | 34 | `source/sound/` | SFX, music, ambience (WAV) |
| `assets/fonts/` | 6 | `source/fonts/` | Tarotheque `.fnt` + glyph tables |
| `assets/system/` | 5 | `source/SystemAssets/` | Launch image, icons, card art |

**Asset path index:** `reference/playdate/libraries/gameAssets.lua` lists imagetable paths used at boot on Playdate.

### `content/` — 10 files

Portable game copy and data. Still in Lua table format — export to JSON/TS when you start implementation.

| File | Source | Purpose |
|------|--------|---------|
| `content/data/cardDescriptions.lua` | `source/data/cardDescriptions.lua` | Merges all suit tables into `CARD_DATA` |
| `content/data/cardDescriptionsMajor.lua` | `source/data/` | Major Arcana fortunes + keywords |
| `content/data/cardDescriptionsCups.lua` | `source/data/` | Cups fortunes + keywords |
| `content/data/cardDescriptionsWands.lua` | `source/data/` | Wands fortunes + keywords |
| `content/data/cardDescriptionsSwords.lua` | `source/data/` | Swords fortunes + keywords |
| `content/data/cardDescriptionsPentacles.lua` | `source/data/` | Pentacles fortunes + keywords |
| `content/data/spreadReadingData.lua` | `source/data/` | Spread names, positions, placeholder readings |
| `content/data/oneCardReadingText.lua` | `source/data/` | Legacy one-card reading copy |
| `content/data/save/diaryEntries.json` | `source/data/save/` | Bundled diary seed / dev fallback |
| `content/data/save/spreads_flavour.md` | `source/data/save/` | Spread flavour notes |

### `reference/playdate/` — 34 files

Playdate-specific Lua kept for **reading only** — scene flow, spread CONFIG tables, deck draw logic, persistence design. Rewrite against your web engine; do not run these files directly.

| Subfolder | Files | Purpose |
|-----------|-------|---------|
| `reference/playdate/scripts/` | `deck.lua`, `card.lua`, `Sound.lua`, `screenShake.lua`, `Sound-Guide.md` | Deck draw, card helpers, audio map |
| `reference/playdate/scripts/decks/` | `allDecks.lua`, `majorArcana.lua`, `cups.lua`, `wands.lua`, `swords.lua`, `pentacles.lua` | Card name lists per suit |
| `reference/playdate/scenes/` | `sceneManager.lua`, `allScenes.lua`, `gameScene.lua`, `postScene.lua` | Scene routing + legacy one-card path |
| `reference/playdate/scenes/spreads/` | `baseSpreadGameScene.lua`, `baseSpreadPostScene.lua`, `spreadSelectionScene.lua`, all `*GameScene.lua` / `*PostScene.lua` | Spread configs + base lifecycle |
| `reference/playdate/libraries/` | `gameAssets.lua`, `utils.lua`, `AnimatedSprite.lua`, `imageCache.lua` | Asset manifest, text utils, animation |
| `reference/playdate/data/save/` | `diaryStore.lua`, `playerProfileStore.lua` | Diary + settings persistence design |

**Spread CONFIG tables** (positions, scales, delays) live in the thin `*GameScene.lua` files, e.g. `threeCardGameScene.lua`, `celticCrossGameScene.lua`.

### `docs/` — 5 files

| File | Source |
|------|--------|
| `docs/porting.md` | `porting.md` |
| `docs/mapping.md` | `source/mapping.md` |
| `docs/improvements_performance.md` | `source/improvements_performance.md` |
| `docs/AGENTS.md` | `AGENTS.md` |
| `docs/playdate-README.md` | `README.md` |

### Root

| File | Source |
|------|--------|
| `LICENSE` | `LICENSE` |

---

## What was **not** migrated (intentionally)

These stay in the Playdate repo only. Rebuild for web from `reference/` + `content/` as needed.

- `source/main.lua`, `source/pdxinfo` — Playdate entry / packaging
- Hub & UI scenes: `titleScene`, `menuScene`, `diary*`, `howTo*`, `settings*`, `creditsScene`, `bufferScene`, `afterDialogueScene`, `cardViewScene`, etc.
- `testing/` — debug entry points
- `builds/`, `.github/`, `.cursor/` — tooling
- `GIGF_stuff.*` — unrelated docs
- Playdate SDK build output (`*.pdx`)

---

## Full file list

### assets/fonts (6)
- `assets/fonts/tarotheque-v1-20.fnt`
- `assets/fonts/tarotheque-v1-20-table-29-35.png`
- `assets/fonts/tarotheque-v2-20.fnt`
- `assets/fonts/tarotheque-v2-20-table-30-36.png`
- `assets/fonts/tarotheque-v111-20-table-29-35.png`
- `assets/fonts/tarotheque-v11111-20-table-29-35.png`

### assets/sound (34)
- `assets/sound/a_but1.wav` … `a_but10.wav`
- `assets/sound/b_button.wav`
- `assets/sound/bgMusic3quieter.wav`
- `assets/sound/cards_fast.wav`, `cards_fast2.wav`, `cards_fast3.wav`
- `assets/sound/cards_slow.wav`, `cards_slow2.wav`
- `assets/sound/cards2_fast2.wav`, `cards2_slow.wav`
- `assets/sound/crank5.wav`
- `assets/sound/dockin1.wav`
- `assets/sound/hahahaha2.wav`, `hahahaha_tail.wav`
- `assets/sound/lockin1.wav`
- `assets/sound/pad_a.wav`, `pad_b.wav`
- `assets/sound/page2-3.wav`, `page3-3.wav`
- `assets/sound/rain1quieter.wav`
- `assets/sound/tuin.wav`
- `assets/sound/undocking4.wav`
- `assets/sound/unlocking1.wav`, `unlocking2.wav`
- `assets/sound/witchpad.wav`

### assets/system (5)
- `assets/system/card.png`
- `assets/system/card_OG.png`
- `assets/system/card-pressed.png`
- `assets/system/icon.png`
- `assets/system/launchImage.png`

### assets/images (200)
- `assets/images/bg/` — 24 PNGs (backgrounds, journal, diary/moonkey/lock anim sheets, title anim)
- `assets/images/cups/` — 28 PNGs (14 cards × normal + zoom)
- `assets/images/majorArcana/` — 44 PNGs (22 cards × normal + zoom)
- `assets/images/pentacles/` — 28 PNGs
- `assets/images/swords/` — 28 PNGs
- `assets/images/wands/` — 28 PNGs
- `assets/images/shuffleAnimation/` — 7 sprite sheets
- `assets/images/spreads/` — 10 PNGs (5 spreads × normal + zoom)
- `assets/images/decknback/` — 2 PNGs
- `assets/images/textscroll/` — 1 PNG

### content (10)
- `content/data/cardDescriptions.lua`
- `content/data/cardDescriptionsMajor.lua`
- `content/data/cardDescriptionsCups.lua`
- `content/data/cardDescriptionsWands.lua`
- `content/data/cardDescriptionsSwords.lua`
- `content/data/cardDescriptionsPentacles.lua`
- `content/data/spreadReadingData.lua`
- `content/data/oneCardReadingText.lua`
- `content/data/save/diaryEntries.json`
- `content/data/save/spreads_flavour.md`

### reference/playdate (34)
- `reference/playdate/scripts/deck.lua`
- `reference/playdate/scripts/card.lua`
- `reference/playdate/scripts/Sound.lua`
- `reference/playdate/scripts/Sound-Guide.md`
- `reference/playdate/scripts/screenShake.lua`
- `reference/playdate/scripts/decks/allDecks.lua`
- `reference/playdate/scripts/decks/majorArcana.lua`
- `reference/playdate/scripts/decks/cups.lua`
- `reference/playdate/scripts/decks/wands.lua`
- `reference/playdate/scripts/decks/swords.lua`
- `reference/playdate/scripts/decks/pentacles.lua`
- `reference/playdate/scenes/sceneManager.lua`
- `reference/playdate/scenes/allScenes.lua`
- `reference/playdate/scenes/gameScene.lua`
- `reference/playdate/scenes/postScene.lua`
- `reference/playdate/scenes/spreads/spreadSelectionScene.lua`
- `reference/playdate/scenes/spreads/baseSpreadGameScene.lua`
- `reference/playdate/scenes/spreads/baseSpreadPostScene.lua`
- `reference/playdate/scenes/spreads/oneCardGameScene.lua`
- `reference/playdate/scenes/spreads/oneCardPostScene.lua`
- `reference/playdate/scenes/spreads/threeCardGameScene.lua`
- `reference/playdate/scenes/spreads/threeCardPostScene.lua`
- `reference/playdate/scenes/spreads/pentagramGameScene.lua`
- `reference/playdate/scenes/spreads/pentagramPostScene.lua`
- `reference/playdate/scenes/spreads/celticCrossGameScene.lua`
- `reference/playdate/scenes/spreads/celticCrossPostScene.lua`
- `reference/playdate/scenes/spreads/horoscopeGameScene.lua`
- `reference/playdate/scenes/spreads/horoscopePostScene.lua`
- `reference/playdate/libraries/gameAssets.lua`
- `reference/playdate/libraries/utils.lua`
- `reference/playdate/libraries/AnimatedSprite.lua`
- `reference/playdate/libraries/imageCache.lua`
- `reference/playdate/data/save/diaryStore.lua`
- `reference/playdate/data/save/playerProfileStore.lua`

### docs (5)
- `docs/porting.md`
- `docs/mapping.md`
- `docs/improvements_performance.md`
- `docs/AGENTS.md`
- `docs/playdate-README.md`

### root (3)
- `LICENSE`
- `README.md`
- `MIGRATION.md`

---

## Re-syncing from Playdate later

When card copy or assets change in the Playdate repo, re-copy the relevant folders:

```powershell
$src = "C:\Games\Playdate\mama Games\Wee Tarot"
$dest = "C:\Games\Wee Tarot Web"

robocopy "$src\source\images" "$dest\assets\images" /E
robocopy "$src\source\sound" "$dest\assets\sound" /E
Copy-Item "$src\source\data\cardDescriptions*.lua" "$dest\content\data\" -Force
# etc.
```

Update this manifest after each sync.
