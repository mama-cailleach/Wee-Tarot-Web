# GitHub Pages hosting

The web game is a static Vite + Phaser build. The canonical playable URL is:

**https://mama-cailleach.github.io/Wee-Tarot-Web/**

Use that URL for the game manual, itch.io embed/link, or any other iframe. Do not treat itch.io as the source of truth for the web build.

## How updates ship

Local work does not go live. Test with `npm run dev` (and `npm run build` / `npm run preview` if you want a production check), then commit and **push to `master`**.

Every push to `master` runs [`.github/workflows/deploy-pages.yml`](../.github/workflows/deploy-pages.yml) automatically:

1. `npm ci`
2. `GITHUB_PAGES=true npm run build` (typecheck + Vite; writes `dist/` with the `/Wee-Tarot-Web/` base)
3. Upload `dist/` and deploy to Pages

The Action is usually green in about a minute. Pages can cache for a short time after that — hard-refresh the live URL if you do not see the new build.

You do **not** need to run the workflow by hand for normal updates. It also has `workflow_dispatch`, so you can click **Run workflow** in the Actions tab to republish the current `master` commit.

## Paths (do not break these)

GitHub project pages serve the site under `/Wee-Tarot-Web/`, not `/`.

| Piece | Behaviour |
|---|---|
| [`vite.config.ts`](../vite.config.ts) `base` | `"/Wee-Tarot-Web/"` when `GITHUB_PAGES=true`; `"/"` for local `npm run dev` / `npm run build` |
| [`src/game/config.ts`](../src/game/config.ts) `ASSET_BASE` | `${import.meta.env.BASE_URL}assets` — follows Vite `base` for every image, sound, and font URL |
| Production HTML | Only `index.html`. `debug-text.html` is local QA and is not published |

Asset copy on Windows cannot use Node `fs.cp` (chmod `EPERM`). The production build copies `assets/` into `dist/assets/` with `copyFile`. Dev still uses `vite-plugin-static-copy` so `/assets` works under `npm run dev`.

## Card data / Lua export

Committed files under `src/game/data/` are what the live build uses.

`npm run build` does **not** run `export:data`. The Lua export (`fengari` / `tojs`) currently fails, which is what broke the first Pages Action.

If you change Lua copy in `content/` or `reference/playdate/`:

1. Run `npm run export:data` or `npm run export:data:ps` locally
2. Commit the generated `src/game/data/` files
3. Push `master`

## If deploy fails

- Actions tab: [Deploy GitHub Pages](https://github.com/mama-cailleach/Wee-Tarot-Web/actions)
- Pages source must stay **GitHub Actions**: repo **Settings → Pages → Build and deployment → Source**
- The `github-pages` environment may ask for approval on the first deploy or after permission changes
- The repo should stay **public** so anyone can play (private Pages needs GitHub Pro)
