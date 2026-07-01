# Porting Wee Tarot Beyond Playdate

## Goal
Make Wee Tarot playable on:
- Mobile (primary)
- Desktop/laptop browsers (secondary, but very valuable)

Keep the original feel:
- 400x240 base resolution
- Black-and-white style
- Sprite-sheet animation
- Scene-based flow

## Quick Recommendation
If your goal is maximum accessibility with one codebase, choose a **web-first port** (mobile + desktop browser).

Then optionally wrap it as an installable mobile app later (PWA or app wrapper).

Why:
- One release reaches iOS, Android, and desktop
- Easy sharing (just a link)
- Faster iteration and updates than app-store-only distribution
- Good fit for a mostly 2D, scene-based game like Wee Tarot

## Web vs Mobile-Only

| Option | Reach | Dev effort | Store friction | Update speed | Best for |
|---|---|---|---|---|---|
| Web-first (browser game) | Very high (mobile + desktop) | Medium | None initially | Fast | Broad accessibility, easy distribution |
| Mobile app only | Medium (mobile users only) | Medium-high | High (app stores, certs, policies) | Slower | Offline-first app strategy, app-store presence |
| Hybrid: web-first then wrap app | Very high | Medium-high | Medium later | Fast web + slower app | Best long-term balance |

## How Realistic Is Lua -> Web?
Short answer: **realistic, but usually not 1:1** because Playdate APIs are platform-specific.

Your game logic and data are portable in concept, but these pieces must be replaced:
- Playdate SDK APIs (`playdate`, `gfx.sprite`, timers, crank input, audio APIs)
- Scene manager integration with Playdate lifecycle
- Input model (buttons/crank -> touch/mouse/keyboard)

The strongest strategy is usually:
1. Keep game rules, card data, flow, and timing behavior
2. Rebuild rendering/input/audio layer for web
3. Recreate the same scene/state architecture

## Practical Porting Options

## 1) Web Rewrite in JavaScript/TypeScript (Recommended)
Use an HTML5 engine/library:
- *[Phaser](https://phaser.io/) (full game framework)* ***BEST CHOICE*** 
- PixiJS (rendering-focused, you build more systems)

Pros:
- Best browser support and ecosystem
- Clean mobile + desktop path
- Easiest to integrate touch, responsive canvas, PWA
- Strong long-term maintainability

Cons:
- Language rewrite (Lua -> JS/TS)
- Initial setup effort

Fit for Wee Tarot:
- Very good: scene-based structure maps well
- Sprite sheets, timers, and transitions are all straightforward

## 2) Keep Lua with LÖVE (plus web build)
Use LÖVE for desktop/mobile, and web-export approaches for browser.

Pros:
- Stay in Lua
- Fast for prototyping if you know Lua well

Cons:
- Web pipeline can feel less polished/modern
- Browser packaging/runtime constraints can be awkward
- More tooling caveats compared to native web engines

Fit for Wee Tarot:
- Good if Lua continuity is your #1 priority
- Less ideal if your #1 priority is smooth browser delivery

## 3) Lua in Browser via Lua VM (Fengari or similar)
Run Lua in JS runtime and render via Canvas/WebGL.

Pros:
- Preserve Lua language

Cons:
- You still rebuild engine/platform APIs
- Smaller ecosystem for game-specific tooling
- Can become a custom-engine project

Fit for Wee Tarot:
- Technically possible, but usually higher risk/complexity than it appears

## 4) Mobile-Only Native/App Framework First
Use Unity/Godot/Defold/etc. targeting iOS/Android only.

Pros:
- Strong app packaging and native distribution

Cons:
- Slower to distribute updates
- No instant desktop-browser play unless you add web target later

Fit for Wee Tarot:
- Works, but not aligned with your “playable outside Playdate for everyone” goal as efficiently as web-first

## Suggested Technical Direction
Build a small portability layer and keep your current architecture concepts.

Port these concepts from current code:
- Scene manager (`switchScene`, fade transitions)
- Scene `init/update/deinit` lifecycle
- Timer orchestration and cleanup discipline
- Data-first card content and spread logic

Replace platform-bound pieces:
- Rendering: canvas/WebGL sprites
- Input: tap/drag/swipe + optional keyboard
- Crank mechanic: substitute with swipe/drag gesture or hold-to-spin UI
- Audio: browser audio API + unlock-on-user-gesture handling

## Preserving the Playdate Look in Web
You can keep the identity strongly:
- Internal render resolution fixed at 400x240
- Integer scaling (`2x`, `3x`) with letterboxing as needed
- 1-bit palette simulation (black/white only)
- Dither patterns in assets/shaders
- Same sprite sheets and animation timing
- Optional CRT/paper/noise overlay very subtle

## Estimated Effort (Rough)
Assuming one developer, part-time, after your current update:

- Vertical slice (1 full reading flow): 2-4 weeks
- Full feature parity: 6-12 weeks
- Polish + device testing + performance pass: 2-4 weeks

Total realistic range: **~2 to 4 months part-time**

Main effort drivers:
- Input redesign (crank replacement UX)
- UI scaling for many phone aspect ratios
- Audio behavior on mobile browsers
- Rebuilding scene framework APIs around existing logic

## Risk Notes
Top risks:
- Recreating Playdate-specific behavior too literally without adapting UX
- Underestimating mobile browser audio/input quirks
- Not testing enough on lower-end Android devices early

Mitigations:
- Build vertical slice first
- Test on real phones from week 1
- Freeze art pipeline early (sprite sheets, scale rules)

## Recommended Plan
1. Finish current Playdate update first.
2. Build a web vertical slice:
   - Title -> shuffle -> draw -> reading
   - One spread only
3. Validate feel on 2-3 phones + desktop browser.
4. Decide stack lock-in (Phaser vs PixiJS) based on slice velocity.
5. Expand to full content and polish.
6. Optionally package as:
   - PWA (installable from browser)
   - App wrapper later for stores

## Decision Summary
Given your goals and concerns:
- Best default choice: **Web-first in JS/TS**
- Keep Playdate aesthetics and scene architecture
- Treat Lua code as design/spec reference, not strict portable runtime code

This gives you the highest accessibility with the least long-term platform friction.
