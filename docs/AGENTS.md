# Wee Tarot — Agent Guide

This file lives in the **Wee Tarot Web** repo. It is Playdate-port reference (copied from the original game). For this repo’s live web build, hosting, and ship loop, read **[github-pages.md](github-pages.md)** before changing Vite `base`, `ASSET_BASE`, `npm run build`, or `.github/workflows/`.

Playdate tarot game (Lua + Playdate SDK). **v1 shipped** on [itch.io](https://mama666.itch.io/wee-tarot); this repo is a **larger update**: multiple spreads, diary, deck filters. Structure is largely in place; active work is **device performance**, copy polish, and refinement.

**Detailed patterns:** [.cursor/rules/wee-tarot.mdc](.cursor/rules/wee-tarot.mdc)  
**Legacy reference (v1 patterns, verify against code):** [.github/copilot-instructions.md](.github/copilot-instructions.md)

---

## Platform constraints

- Resolution: **400×240**, 1-bit display
- **Memory is tight** — every scene needs thorough `deinit()` (sprites, timers, sounds)
- **Crank + A/B** primary input
- **Simulator is not enough for perf** — hitches and audio drops often appear only on hardware. Treat [source/improvements_performance.md](source/improvements_performance.md) and the developer’s device notes as truth.

---

## Scene flow (v2)

```
TitleScene → MenuScene → SpreadSelectionScene
                              ├─ one_card ("1-bit Fortune") → GameScene → PostScene  [legacy path]
                              ├─ three_card → ThreeCardGameScene → ThreeCardPostScene
                              ├─ pentagram → PentagramGameScene → PentagramPostScene
                              ├─ celtic_cross → CelticCrossGameScene → CelticCrossPostScene
                              └─ horoscope → HoroscopeGameScene → HoroscopePostScene
MenuScene also → SettingsScene, DiaryScene, How-to scenes
```

- Transitions: `SCENE_MANAGER:switchScene(SceneClass, ...)` in [source/scenes/sceneManager.lua](source/scenes/sceneManager.lua)
- Scene registration: [source/scenes/allScenes.lua](source/scenes/allScenes.lua)
- Entry: [source/main.lua](source/main.lua) — `SCENE_MANAGER`, `selectedDeck`, `Sound.init()`, FPS overlay

---

## Globals

| Name | Role |
|------|------|
| `SCENE_MANAGER` | Scene transitions with fade |
| `selectedDeck` | `"full"`, `"major"`, `"minor"`, suit keys, `"alternate"` — set in spread selection |
| `Sound` | Module API in [source/scripts/Sound.lua](source/scripts/Sound.lua) — prefer over raw global samples |
| `PlayerProfileStore` | Settings persistence ([source/data/save/playerProfileStore.lua](source/data/save/playerProfileStore.lua)) |

---

## Spread architecture

- **Base:** [source/scenes/spreads/baseSpreadGameScene.lua](source/scenes/spreads/baseSpreadGameScene.lua), [baseSpreadPostScene.lua](source/scenes/spreads/baseSpreadPostScene.lua)
- **Per spread:** `*GameScene.lua` exports a `CONFIG` table + thin subclass; `*PostScene.lua` sets `postSceneClass` in config
- **Selection UI:** [source/scenes/spreads/spreadSelectionScene.lua](source/scenes/spreads/spreadSelectionScene.lua)

`BaseSpreadGameScene` state machine (approx.): `shuffle` → deck lay / explode → `drawCardsLogic` → `revealCardsSequentially` → card selection → post scene.

Do **not** split placement into a new scene for perf without explicit request — see perf doc.

---

## Asset preload

Heavy images/imagetables load during boot via [source/libraries/gameAssets.lua](source/libraries/gameAssets.lua) (one step per frame in [source/main.lua](source/main.lua) while `launchImage` is visible). Scenes should use `GameAssets.get*()` — do not add scene-entry preload without a strong reason.

## Performance-first checklist

Read [source/improvements_performance.md](source/improvements_performance.md) before changing spread scenes.

Likely hot spots:

1. **Spread game entry** — cloth/background swap, first reveal frame in `BaseSpreadGameScene`
2. **`drawCardsLogic()`** — card creation, `self.cardImageCache`, dimmed image generation
3. **`revealCardsSequentially()`** — timer bursts + SFX stacking
4. **`BaseSpreadPostScene:init()`** — text pagination (`buildTextPages`), **`persistDiaryEntry()` in init**, Dinah/scroll setup

Preferred approaches (from perf plan):

- Spread heavy work across frames; avoid doing everything on first reveal frame
- Stage cloth change, then card creation after a short delay
- Batch card creation; delay nonessential SFX 1–2 frames
- **Move diary / file I/O out of post `init()`** when hitching on entry
- Preload or reuse module-level imagetables (already used for shuffle assets in base game scene)

Success = no obvious audio hiccup on reveal entry; no standout frame drop on device; smooth post entry.

---

## Key files

| Area | Path |
|------|------|
| Scene manager | `source/scenes/sceneManager.lua` |
| Spread bases | `source/scenes/spreads/baseSpreadGameScene.lua`, `baseSpreadPostScene.lua` |
| Legacy single card | `source/scenes/gameScene.lua`, `postScene.lua` |
| Card data | `source/data/cardDescriptions*.lua`, `cardDescriptions.lua` |
| Spread copy | `source/data/spreadReadingData.lua` |
| Deck / draw | `source/scripts/deck.lua`, `source/scripts/decks/` |
| Diary save | `source/data/save/diaryStore.lua` |
| Image LRU | `source/libraries/imageCache.lua` |
| Animation | `source/libraries/AnimatedSprite.lua` |
| Utils (text) | `source/libraries/utils.lua` |
| Debug scenes | `testing/` |

---

## Agent do / don’t

**Do**

- Keep diffs minimal; match existing Lua/style in the file you edit
- Implement `deinit()` for new sprites, timers (`revealTimers`, `promptTypeTimers`, crank timers), and sounds
- Use `Sound.playSFX`, `Sound.playABut`, `Sound.startCrankLoop` / `Sound.stopCrankLoop` where applicable
- Ask for **spread name + moment** (enter reveal, enter post, etc.) when debugging perf
- Confirm fixes on **Playdate hardware**

**Don’t**

- Treat Simulator FPS as proof of perf fixes
- Add large refactors or new scenes without a clear perf or feature ask
- Reintroduce global sound handles in `main.lua` (use `Sound` module)
- Edit [porting.md](porting.md) or rewrite README unless asked

---

## Debug

- FPS: `pd.drawFPS(380, 5)` in `main.lua` (on by default)
- Alternate entry points: `testing/mainDebug.lua`, spread/card debug scenes
- Commented imports in `main.lua` for shuffle animation tests

---

## Out of scope unless requested

- Web/mobile port (`porting.md`) — except GitHub Pages path/deploy work, which is in-repo and documented in [github-pages.md](github-pages.md)
- Replacing `.github/copilot-instructions.md` wholesale (cross-linked only)
