# Wee Tarot Web

Web port of [Wee Tarot](https://mama666.itch.io/wee-tarot). This repo is separate from the Playdate version.

**Canonical Playdate repo:** `C:\Games\Playdate\mama Games\Wee Tarot`

## Layout

| Path | Purpose |
|------|---------|
| `assets/` | Images, audio, fonts (copied from Playdate) |
| `content/` | Card copy, spread text, diary seed data (Lua tables — convert to JSON/TS when you pick a stack) |
| `reference/playdate/` | Read-only Playdate Lua for architecture, spread configs, deck logic |
| `docs/` | Porting notes, flow maps, performance notes from Playdate |

See [MIGRATION.md](MIGRATION.md) for the full list of what was copied and from where.

## Next steps

1. Choose web stack (see `docs/porting.md`)
2. Export `content/data/*.lua` to JSON or TypeScript modules
3. Build a vertical slice: title → one spread → reading
4. Open this folder in its own Cursor window
